# lib/services/remote_control_service.dart

## Purpose

Defines the transport contract used by the remote controller and replaces the WebSocket implementation in tests.

## Methods

- `connect(String relayUrl)`: opens the relay connection.
- `createRoom(displayName)`: asks the relay for a host room.
- `joinRoom(code, displayName)`: asks to join a host room.
- `decideJoin(approved)`: host approval or decline.
- `sendHaptic(action, strengthPercent)`: controller commands.
- `sendHapticStatus(...)`: host playback feedback.
- `leave()`: leaves the room.
- `close()`: releases the transport.
- `events`: broadcast stream of typed `RemoteEvent` values.

## Notes

The interface contains no Flutter UI code, so the controller can be tested with a fake service. The production implementation is `WebSocketRemoteControlService`.
