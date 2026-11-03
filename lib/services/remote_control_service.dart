import '../models/remote_models.dart';

abstract interface class RemoteControlService {
  Stream<RemoteEvent> get events;

  Future<void> connect(String relayUrl);

  void createRoom(String displayName);

  void joinRoom({required String code, required String displayName});

  void decideJoin(bool approved);

  void sendHaptic(RemoteHapticAction action, {int? strengthPercent});

  void sendHapticStatus({
    required bool playing,
    required int strengthPercent,
    String? message,
  });

  void leave();

  Future<void> close();
}
