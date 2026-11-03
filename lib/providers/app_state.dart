import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vibration_models.dart';
import '../services/android_vibration_service.dart';
import '../services/preview_vibration_service.dart';
import '../services/vibration_service.dart';

final selectedTabProvider = NotifierProvider<SelectedTabController, int>(
  SelectedTabController.new,
);

class SelectedTabController extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) {
    state = index;
  }
}

final vibrationServiceProvider = Provider<VibrationService>((ref) {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return const AndroidVibrationService();
  }
  return const PreviewVibrationService();
});

final capabilityProvider = FutureProvider<CapabilityReport>((ref) {
  return ref.watch(vibrationServiceProvider).getCapabilities();
});

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => AppSettings.defaults;

  void setDefaultDuration(int value) {
    state = state.copyWith(defaultDurationMs: value);
  }

  void setDefaultStrength(int value) {
    state = state.copyWith(defaultStrengthPercent: value);
  }

  void setHapticsEnabled(bool value) {
    state = state.copyWith(appHapticsEnabled: value);
  }

  void reset() {
    state = AppSettings.defaults;
  }
}

final presetControllerProvider =
    NotifierProvider<PresetController, List<VibrationPreset>>(
      PresetController.new,
    );

class PresetController extends Notifier<List<VibrationPreset>> {
  @override
  List<VibrationPreset> build() => const [];

  void add(VibrationPreset preset) {
    state = [...state, preset];
  }

  void remove(String id) {
    state = state.where((preset) => preset.id != id).toList();
  }

  void clear() {
    state = const [];
  }
}

final playbackControllerProvider =
    NotifierProvider<PlaybackController, PlaybackState>(PlaybackController.new);

class PlaybackController extends Notifier<PlaybackState> {
  Timer? _timer;
  bool _disposed = false;
  int _session = 0;

  @override
  PlaybackState build() {
    ref.onDispose(() {
      _disposed = true;
      _timer?.cancel();
    });
    return const PlaybackState.idle();
  }

  Future<void> play(VibrationRequest request) async {
    final session = ++_session;
    final settings = ref.read(settingsControllerProvider);
    if (!settings.appHapticsEnabled) {
      _timer?.cancel();
      state = const PlaybackState(
        isPlaying: false,
        message: 'App haptics are disabled in Settings.',
      );
      return;
    }

    final service = ref.read(vibrationServiceProvider);
    _timer?.cancel();
    state = const PlaybackState(
      isPlaying: true,
      message: 'Starting playback...',
    );

    try {
      final result = await service.play(request);
      if (_disposed || session != _session) {
        return;
      }

      if (!result.started) {
        state = PlaybackState(
          isPlaying: false,
          lastResult: result,
          message: 'Playback did not start.',
        );
        return;
      }

      state = PlaybackState(
        isPlaying: true,
        lastResult: result,
        message: result.warnings.isEmpty ? 'Playing' : result.warnings.first,
      );

      _timer = Timer(Duration(milliseconds: request.totalDurationMs), () {
        if (_disposed || session != _session) {
          return;
        }
        state = PlaybackState(
          isPlaying: false,
          lastResult: result,
          message: 'Playback finished.',
        );
      });
    } on Object catch (error) {
      if (_disposed || session != _session) {
        return;
      }
      state = PlaybackState(
        isPlaying: false,
        message: 'Could not play: $error',
      );
    }
  }

  Future<void> stop() async {
    final session = ++_session;
    _timer?.cancel();
    try {
      await ref.read(vibrationServiceProvider).stop();
      if (_disposed || session != _session) {
        return;
      }
      state = const PlaybackState(isPlaying: false, message: 'Stopped.');
    } on Object catch (error) {
      if (_disposed || session != _session) {
        return;
      }
      state = PlaybackState(
        isPlaying: false,
        message: 'Could not stop playback: $error',
      );
    }
  }
}
