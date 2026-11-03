# test/remote_control_test.dart

## Purpose

Covers remote-session validation, protocol parsing, and the two UI flows with a fake transport.

## Coverage

- `RemoteValidator` accepts six-digit codes, `ws`/`wss` URLs, and valid names; it rejects malformed input.
- `parseRemoteEvent` maps session and haptic messages and rejects unknown or malformed ones.
- Host flow: create room, receive join request, approve, receive haptic start, play through the recording haptics service, stop, and end.
- Controller flow: join, receive session start, hold and move the remote graph, receive host status, and end.
- The fake service records connect, create, join, decision, haptic, status, leave, and close calls.

## Notes

Widget tests use a 900x1400 surface and override both the vibration service and the remote service factory. Indeterminate progress indicators mean some waits use explicit `pump` calls instead of `pumpAndSettle`.
