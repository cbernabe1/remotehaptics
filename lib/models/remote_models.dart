enum RemoteRole {
  host,
  controller;

  String get label => switch (this) {
    RemoteRole.host => 'Host',
    RemoteRole.controller => 'Controller',
  };

  String get wireName => name;

  static RemoteRole? fromWire(Object? value) {
    return switch (value) {
      'host' => RemoteRole.host,
      'controller' => RemoteRole.controller,
      _ => null,
    };
  }
}

enum RemotePhase {
  idle,
  connecting,
  waitingForRoom,
  awaitingApproval,
  active,
  ended,
  error;

  bool get isBusy =>
      this == RemotePhase.connecting ||
      this == RemotePhase.waitingForRoom ||
      this == RemotePhase.awaitingApproval;
}

enum RemoteHapticAction {
  start,
  update,
  stop;

  static RemoteHapticAction? fromWire(Object? value) {
    return switch (value) {
      'start' => RemoteHapticAction.start,
      'update' => RemoteHapticAction.update,
      'stop' => RemoteHapticAction.stop,
      _ => null,
    };
  }
}

class RemoteState {
  const RemoteState({
    this.phase = RemotePhase.idle,
    this.role,
    this.roomCode,
    this.peerName,
    this.message,
    this.strengthPercent = 60,
    this.remotePlaying = false,
    this.relayUrl,
    this.displayName = 'My phone',
  });

  final RemotePhase phase;
  final RemoteRole? role;
  final String? roomCode;
  final String? peerName;
  final String? message;
  final int strengthPercent;
  final bool remotePlaying;
  final String? relayUrl;
  final String displayName;

  bool get isActive => phase == RemotePhase.active;
  bool get isBusy => phase.isBusy;
  bool get isIdle => phase == RemotePhase.idle;
  bool get isHost => role == RemoteRole.host;
  bool get isController => role == RemoteRole.controller;

  RemoteState copyWith({
    RemotePhase? phase,
    RemoteRole? role,
    String? roomCode,
    String? peerName,
    String? message,
    int? strengthPercent,
    bool? remotePlaying,
    String? relayUrl,
    String? displayName,
  }) {
    return RemoteState(
      phase: phase ?? this.phase,
      role: role ?? this.role,
      roomCode: roomCode ?? this.roomCode,
      peerName: peerName ?? this.peerName,
      message: message ?? this.message,
      strengthPercent: strengthPercent ?? this.strengthPercent,
      remotePlaying: remotePlaying ?? this.remotePlaying,
      relayUrl: relayUrl ?? this.relayUrl,
      displayName: displayName ?? this.displayName,
    );
  }
}

sealed class RemoteEvent {
  const RemoteEvent();
}

class RemoteRoomCreated extends RemoteEvent {
  const RemoteRoomCreated(this.code);

  final String code;
}

class RemoteJoinWaiting extends RemoteEvent {
  const RemoteJoinWaiting();
}

class RemoteJoinRequest extends RemoteEvent {
  const RemoteJoinRequest(this.name);

  final String name;
}

class RemoteJoinDeclined extends RemoteEvent {
  const RemoteJoinDeclined(this.message);

  final String message;
}

class RemoteJoinCancelled extends RemoteEvent {
  const RemoteJoinCancelled(this.message);

  final String message;
}

class RemoteSessionStarted extends RemoteEvent {
  const RemoteSessionStarted({
    required this.role,
    required this.peerName,
    required this.code,
  });

  final RemoteRole role;
  final String peerName;
  final String code;
}

class RemoteHapticCommand extends RemoteEvent {
  const RemoteHapticCommand({required this.action, this.strength});

  final RemoteHapticAction action;
  final int? strength;
}

class RemoteHapticStatus extends RemoteEvent {
  const RemoteHapticStatus({
    required this.playing,
    required this.strength,
    required this.message,
  });

  final bool playing;
  final int strength;
  final String message;
}

class RemotePeerLeft extends RemoteEvent {
  const RemotePeerLeft(this.message);

  final String message;
}

class RemoteSessionEnded extends RemoteEvent {
  const RemoteSessionEnded(this.message);

  final String message;
}

class RemoteServerError extends RemoteEvent {
  const RemoteServerError({required this.code, required this.message});

  final String code;
  final String message;
}

class RemoteDisconnected extends RemoteEvent {
  const RemoteDisconnected(this.message);

  final String message;
}

RemoteEvent? parseRemoteEvent(Map<String, dynamic> json) {
  final message = json['message'];
  switch (json['type']) {
    case 'room_created':
      final code = json['code'];
      return code is String ? RemoteRoomCreated(code) : null;
    case 'join_waiting':
      return const RemoteJoinWaiting();
    case 'join_request':
      return RemoteJoinRequest(_stringOr(message, 'The other phone'));
    case 'join_declined':
      return RemoteJoinDeclined(_stringOr(message, 'The host declined.'));
    case 'join_cancelled':
      return RemoteJoinCancelled(_stringOr(message, 'The request ended.'));
    case 'session_started':
      final role = RemoteRole.fromWire(json['role']);
      if (role == null) {
        return null;
      }
      return RemoteSessionStarted(
        role: role,
        peerName: _stringOr(json['peerName'], 'The other phone'),
        code: _stringOr(json['code'], ''),
      );
    case 'haptic':
      final action = RemoteHapticAction.fromWire(json['action']);
      if (action == null) {
        return null;
      }
      final strength = json['strength'];
      return RemoteHapticCommand(
        action: action,
        strength: strength is int ? strength : null,
      );
    case 'haptic_status':
      final playing = json['playing'];
      final strength = json['strength'];
      return RemoteHapticStatus(
        playing: playing is bool && playing,
        strength: strength is int ? strength : 0,
        message: _stringOr(message, ''),
      );
    case 'peer_left':
      return RemotePeerLeft(_stringOr(message, 'The other phone left.'));
    case 'session_ended':
      return RemoteSessionEnded(_stringOr(message, 'The session ended.'));
    case 'error':
      return RemoteServerError(
        code: _stringOr(json['code'], 'unknown'),
        message: _stringOr(message, 'The relay returned an error.'),
      );
    default:
      return null;
  }
}

String _stringOr(Object? value, String fallback) {
  return value is String && value.isNotEmpty ? value : fallback;
}
