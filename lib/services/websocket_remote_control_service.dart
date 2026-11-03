import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/remote_models.dart';
import 'remote_control_service.dart';

class WebSocketRemoteControlService implements RemoteControlService {
  WebSocketRemoteControlService({
    this.connectTimeout = const Duration(seconds: 10),
  });

  final Duration connectTimeout;

  final StreamController<RemoteEvent> _events =
      StreamController<RemoteEvent>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  bool _closing = false;

  @override
  Stream<RemoteEvent> get events => _events.stream;

  @override
  Future<void> connect(String relayUrl) async {
    await _teardown(notify: false);
    final uri = Uri.parse(relayUrl.trim());
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    try {
      await channel.ready.timeout(connectTimeout);
    } on Object {
      _channel = null;
      await channel.sink.close();
      rethrow;
    }

    _subscription = channel.stream.listen(
      _handleData,
      onError: _handleError,
      onDone: _handleDone,
      cancelOnError: false,
    );
  }

  @override
  void createRoom(String displayName) {
    _send({'type': 'create_room', 'name': displayName});
  }

  @override
  void joinRoom({required String code, required String displayName}) {
    _send({'type': 'join_room', 'code': code, 'name': displayName});
  }

  @override
  void decideJoin(bool approved) {
    _send({'type': 'join_decision', 'approved': approved});
  }

  @override
  void sendHaptic(RemoteHapticAction action, {int? strengthPercent}) {
    final payload = <String, Object?>{'type': 'haptic', 'action': action.name};
    if (strengthPercent != null) {
      payload['strength'] = strengthPercent;
    }
    _send(payload);
  }

  @override
  void sendHapticStatus({
    required bool playing,
    required int strengthPercent,
    String? message,
  }) {
    final payload = <String, Object?>{
      'type': 'haptic_status',
      'playing': playing,
      'strength': strengthPercent,
    };
    if (message != null) {
      payload['message'] = message;
    }
    _send(payload);
  }

  @override
  void leave() {
    _send({'type': 'leave'});
  }

  @override
  Future<void> close() async {
    await _teardown(notify: false);
    if (!_events.isClosed) {
      await _events.close();
    }
  }

  void _handleData(dynamic data) {
    if (data is! String) {
      return;
    }
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map) {
        return;
      }
      final event = parseRemoteEvent(decoded.cast<String, dynamic>());
      if (event != null) {
        _emit(event);
      }
    } on FormatException {
      return;
    }
  }

  void _handleError(Object error) {
    _emit(const RemoteDisconnected('The relay connection was lost.'));
  }

  void _handleDone() {
    if (!_closing) {
      _emit(const RemoteDisconnected('The relay connection closed.'));
    }
  }

  void _send(Map<String, Object?> payload) {
    final sink = _channel?.sink;
    if (sink == null) {
      return;
    }
    try {
      sink.add(jsonEncode(payload));
    } on Object {
      _emit(const RemoteDisconnected('Could not send to the relay.'));
    }
  }

  void _emit(RemoteEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }

  Future<void> _teardown({required bool notify}) async {
    _closing = !notify;
    await _subscription?.cancel();
    _subscription = null;
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      await channel.sink.close();
    }
    _closing = false;
  }
}
