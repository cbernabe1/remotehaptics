# lib/services/websocket_remote_control_service.dart

## Purpose

Implements the remote service contract over a WebSocket using `web_socket_channel`.

## Behavior

- `connect` closes any previous channel, opens the URL, waits for `ready` with a 10-second timeout, then starts listening.
- Incoming JSON is decoded and passed to `parseRemoteEvent`; malformed JSON is ignored.
- Outgoing methods serialize the small relay protocol and silently stop if the socket is unavailable.
- `close` cancels the subscription and closes the socket. Intentional closes do not emit a disconnect event.
- Stream errors and unexpected closes emit `RemoteDisconnected`.

## Dependencies

- `web_socket_channel`
- `dart:convert`
- `lib/models/remote_models.dart`

## Error handling

Connection failures are rethrown to the controller, which shows a retry state. Runtime socket failures become a typed disconnect event so the controller can stop playback and release the session.
