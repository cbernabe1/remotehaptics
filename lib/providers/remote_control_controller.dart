import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/remote_config.dart';
import '../models/remote_models.dart';
import '../models/vibration_models.dart';
import '../services/remote_control_service.dart';
import '../services/websocket_remote_control_service.dart';
import 'app_state.dart';

typedef RemoteServiceFactory = RemoteControlService Function();

final remoteServiceFactoryProvider = Provider<RemoteServiceFactory>(
  (ref) => WebSocketRemoteControlService.new,
);

final remoteControllerProvider =
    NotifierProvider<RemoteController, RemoteState>(RemoteController.new);

class RemoteController extends Notifier<RemoteState> {
  static const _strengthDebounceMs = 90;

  RemoteControlService? _service;
  StreamSubscription<RemoteEvent>? _subscription;
  Timer? _strengthDebounce;
  Timer? _holdCapTimer;
  int _lastSentStrength = 60;
  int _hapticToken = 0;
  int _connectToken = 0;
  bool _disposed = false;

  @override
  RemoteState build() {
    ref.onDispose(() {
      _disposed = true;
      _strengthDebounce?.cancel();
      _holdCapTimer?.cancel();
      unawaited(_subscription?.cancel());
      final service = _service;
      _service = null;
      if (service != null) {
        service.leave();
        unawaited(service.close());
      }
    });
    return const RemoteState();
  }

  Future<void> host({
    required String relayUrl,
    required String displayName,
  }) async {
    if (state.isBusy || state.isActive) {
      return;
    }
    final connected = await _open(
      relayUrl: relayUrl,
      role: RemoteRole.host,
      displayName: displayName,
    );
    if (!connected || _service == null) {
      return;
    }

    state = RemoteState(
      phase: RemotePhase.waitingForRoom,
      role: RemoteRole.host,
      relayUrl: relayUrl,
      displayName: displayName,
      strengthPercent: state.strengthPercent,
      message: 'Creating a room...',
    );
    _service!.createRoom(displayName);
  }

  Future<void> join({
    required String relayUrl,
    required String code,
    required String displayName,
  }) async {
    if (state.isBusy || state.isActive) {
      return;
    }
    final connected = await _open(
      relayUrl: relayUrl,
      role: RemoteRole.controller,
      displayName: displayName,
    );
    if (!connected || _service == null) {
      return;
    }

    state = RemoteState(
      phase: RemotePhase.awaitingApproval,
      role: RemoteRole.controller,
      relayUrl: relayUrl,
      displayName: displayName,
      strengthPercent: state.strengthPercent,
      message: 'Waiting for host approval...',
    );
    _service!.joinRoom(code: code, displayName: displayName);
  }

  void approve() {
    if (!state.isHost || state.phase != RemotePhase.awaitingApproval) {
      return;
    }
    state = state.copyWith(message: 'Approving...');
    _service?.decideJoin(true);
  }

  void decline() {
    if (!state.isHost || state.phase != RemotePhase.awaitingApproval) {
      return;
    }
    _service?.decideJoin(false);
  }

  void setStrength(int value) {
    if (!state.isController || !state.isActive) {
      return;
    }
    final strength = value.clamp(1, 100).toInt();
    state = state.copyWith(strengthPercent: strength);
    _strengthDebounce?.cancel();
    _strengthDebounce = Timer(
      const Duration(milliseconds: _strengthDebounceMs),
      () {
        if (!state.isController || !state.isActive) {
          return;
        }
        if (strength == _lastSentStrength) {
          return;
        }
        _lastSentStrength = strength;
        _service?.sendHaptic(
          RemoteHapticAction.update,
          strengthPercent: strength,
        );
      },
    );
  }

  void startHold() {
    if (!state.isController || !state.isActive) {
      return;
    }
    _strengthDebounce?.cancel();
    _holdCapTimer?.cancel();
    _lastSentStrength = state.strengthPercent;
    _service?.sendHaptic(
      RemoteHapticAction.start,
      strengthPercent: state.strengthPercent,
    );
    state = state.copyWith(
      remotePlaying: false,
      message: 'Sending pulse to ${state.peerName}.',
    );
    _holdCapTimer = Timer(
      const Duration(milliseconds: RemoteConfig.maxHoldMs),
      stopHold,
    );
  }

  void stopHold() {
    if (!state.isController || !state.isActive) {
      return;
    }
    _strengthDebounce?.cancel();
    _holdCapTimer?.cancel();
    _service?.sendHaptic(RemoteHapticAction.stop);
    state = state.copyWith(remotePlaying: false);
  }

  Future<void> disconnect() async {
    _connectToken++;
    if (state.isController && state.isActive) {
      _service?.sendHaptic(RemoteHapticAction.stop);
    }
    if (state.isHost && state.isActive) {
      await _stopRemotePlayback(sendStatus: false);
    }
    _hapticToken++;
    _strengthDebounce?.cancel();
    _holdCapTimer?.cancel();
    _service?.leave();
    state = const RemoteState();
    await _releaseService(notify: false);
  }

  Future<void> reset() => disconnect();

  Future<bool> _open({
    required String relayUrl,
    required RemoteRole role,
    required String displayName,
  }) async {
    await _releaseService(notify: false);
    final token = ++_connectToken;
    final service = ref.read(remoteServiceFactoryProvider)();
    _service = service;
    _subscription = service.events.listen(_handleEvent);
    state = RemoteState(
      phase: RemotePhase.connecting,
      role: role,
      relayUrl: relayUrl,
      displayName: displayName,
      strengthPercent: state.strengthPercent,
      message: 'Connecting to the relay...',
    );

    try {
      await service.connect(relayUrl);
      if (_disposed || token != _connectToken) {
        await service.close();
        return false;
      }
      return true;
    } on Object {
      if (_disposed || token != _connectToken) {
        await service.close();
        return false;
      }
      await _releaseService(notify: false);
      state = RemoteState(
        phase: RemotePhase.error,
        role: role,
        relayUrl: relayUrl,
        displayName: displayName,
        strengthPercent: state.strengthPercent,
        message: 'Could not connect. Check the relay URL and network.',
      );
      return false;
    }
  }

  void _handleEvent(RemoteEvent event) {
    if (_disposed) {
      return;
    }

    switch (event) {
      case RemoteRoomCreated():
        state = RemoteState(
          phase: RemotePhase.waitingForRoom,
          role: RemoteRole.host,
          roomCode: event.code,
          relayUrl: state.relayUrl,
          displayName: state.displayName,
          strengthPercent: state.strengthPercent,
          message: 'Share this code with the other phone.',
        );
      case RemoteJoinWaiting():
        state = state.copyWith(
          phase: RemotePhase.awaitingApproval,
          message: 'Waiting for host approval...',
        );
      case RemoteJoinRequest():
        state = state.copyWith(
          phase: RemotePhase.awaitingApproval,
          peerName: event.name,
          message: '${event.name} wants to control this phone.',
        );
      case RemoteJoinDeclined():
        _finish(event.message, RemotePhase.ended);
      case RemoteJoinCancelled():
        state = RemoteState(
          phase: RemotePhase.waitingForRoom,
          role: RemoteRole.host,
          roomCode: state.roomCode,
          relayUrl: state.relayUrl,
          displayName: state.displayName,
          strengthPercent: state.strengthPercent,
          message: event.message,
        );
      case RemoteSessionStarted():
        _lastSentStrength = state.strengthPercent;
        state = RemoteState(
          phase: RemotePhase.active,
          role: event.role,
          roomCode: event.code,
          peerName: event.peerName,
          relayUrl: state.relayUrl,
          displayName: state.displayName,
          strengthPercent: state.strengthPercent,
          message: 'Connected to ${event.peerName}.',
        );
      case RemoteHapticCommand():
        _handleRemoteHaptic(event);
      case RemoteHapticStatus():
        if (!state.isController || !state.isActive) {
          return;
        }
        state = state.copyWith(
          remotePlaying: event.playing,
          strengthPercent: event.strength > 0
              ? event.strength
              : state.strengthPercent,
          message: event.message.isNotEmpty
              ? event.message
              : event.playing
              ? '${state.peerName} is playing.'
              : '${state.peerName} stopped.',
        );
      case RemotePeerLeft():
        _finish(event.message, RemotePhase.ended);
      case RemoteSessionEnded():
        _finish(event.message, RemotePhase.ended);
      case RemoteServerError():
        _handleServerError(event);
      case RemoteDisconnected():
        _finish(event.message, RemotePhase.error);
    }
  }

  void _handleRemoteHaptic(RemoteHapticCommand event) {
    if (!state.isHost || !state.isActive) {
      return;
    }

    switch (event.action) {
      case RemoteHapticAction.start:
        _strengthDebounce?.cancel();
        _holdCapTimer?.cancel();
        final strength = event.strength ?? state.strengthPercent;
        _lastSentStrength = strength;
        state = state.copyWith(strengthPercent: strength, remotePlaying: true);
        unawaited(_playRemote(strength));
        _holdCapTimer = Timer(
          const Duration(milliseconds: RemoteConfig.maxHoldMs),
          () => unawaited(_stopRemotePlayback(sendStatus: true)),
        );
      case RemoteHapticAction.update:
        final strength = event.strength;
        if (strength == null) {
          return;
        }
        state = state.copyWith(strengthPercent: strength);
        _strengthDebounce?.cancel();
        _strengthDebounce = Timer(
          const Duration(milliseconds: _strengthDebounceMs),
          () {
            if (!state.isHost || !state.isActive) {
              return;
            }
            if (strength == _lastSentStrength) {
              return;
            }
            _lastSentStrength = strength;
            state = state.copyWith(remotePlaying: true);
            unawaited(_playRemote(strength));
          },
        );
      case RemoteHapticAction.stop:
        _strengthDebounce?.cancel();
        _holdCapTimer?.cancel();
        unawaited(_stopRemotePlayback(sendStatus: true));
    }
  }

  Future<void> _playRemote(int strength) async {
    final token = ++_hapticToken;
    await ref
        .read(playbackControllerProvider.notifier)
        .play(
          VibrationRequest.single(
            durationMs: RemoteConfig.maxHoldMs,
            strengthPercent: strength,
          ),
        );
    if (_disposed || token != _hapticToken || !state.isActive) {
      return;
    }
    final playback = ref.read(playbackControllerProvider);
    state = state.copyWith(
      remotePlaying: playback.isPlaying,
      message: playback.message ?? state.message,
    );
    _sendStatus();
  }

  Future<void> _stopRemotePlayback({required bool sendStatus}) async {
    final token = ++_hapticToken;
    _strengthDebounce?.cancel();
    _holdCapTimer?.cancel();
    await ref.read(playbackControllerProvider.notifier).stop();
    if (_disposed || token != _hapticToken || !state.isActive) {
      return;
    }
    state = state.copyWith(remotePlaying: false, message: 'Remote stopped.');
    if (sendStatus) {
      _sendStatus();
    }
  }

  void _sendStatus() {
    if (!state.isActive || !state.isHost) {
      return;
    }
    final playback = ref.read(playbackControllerProvider);
    _service?.sendHapticStatus(
      playing: playback.isPlaying,
      strengthPercent: state.strengthPercent,
      message: playback.message,
    );
  }

  void _handleServerError(RemoteServerError event) {
    final fatal =
        !state.isActive &&
        (event.code == 'room_not_found' ||
            event.code == 'room_busy' ||
            event.code == 'relay_full' ||
            event.code == 'rate_limited');
    if (!fatal) {
      state = state.copyWith(message: event.message);
      return;
    }
    _finish(event.message, RemotePhase.error);
  }

  void _finish(String message, RemotePhase phase) {
    final role = state.role;
    final shouldStop = state.isHost && state.isActive;
    _hapticToken++;
    _strengthDebounce?.cancel();
    _holdCapTimer?.cancel();
    if (shouldStop) {
      unawaited(ref.read(playbackControllerProvider.notifier).stop());
    }
    state = RemoteState(
      phase: phase,
      role: role,
      relayUrl: state.relayUrl,
      displayName: state.displayName,
      strengthPercent: state.strengthPercent,
      message: message,
    );
    unawaited(_releaseService(notify: false));
  }

  Future<void> _releaseService({required bool notify}) async {
    final service = _service;
    _service = null;
    await _subscription?.cancel();
    _subscription = null;
    if (service == null) {
      return;
    }
    if (notify) {
      service.leave();
    }
    await service.close();
  }
}
