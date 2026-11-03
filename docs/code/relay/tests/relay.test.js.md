# relay/tests/relay.test.js

## Purpose

Integration tests for the in-memory WebSocket relay. They start a real relay on an ephemeral local port, connect real `ws` clients, and verify the pairing and haptic protocol end to end.

## Key responsibilities

- `startRelay(t)` starts `createRelayServer` with short expiry windows and a no-op logger, then registers cleanup with Node's test context.
- `openSocket(url)` resolves once a client WebSocket is connected and rejects on an initial connection error.
- `watch(socket)` buffers incoming JSON messages and exposes a `next()` helper that either returns a queued message or waits with a timeout.
- `pairPhones(t, relayUrl)` creates a host room, joins a controller, waits for the host's `join_request`, approves it, and asserts both peers receive `session_started` with the correct roles.
- Four test cases cover:
  - successful pairing, controller `haptic` relay, and host `haptic_status` relay;
  - declining a controller without closing the host room;
  - rejecting host-originated haptic commands and controller-originated approval decisions;
  - ending the session when the controller disconnects.

## Inputs and outputs

- Inputs: local relay options from `startRelay` and JSON protocol messages written by the test clients.
- Outputs: assertions against relay messages; no files, database, or permanent network state.
- The Relay server is always closed through `t.after`, and connected sockets are closed in each test's cleanup.

## Dependencies

- Node.js built-in `node:test` and `node:assert/strict`.
- The `ws` WebSocket client.
- `createRelayServer` from `../server.js`.

## Error handling

- Socket connection failures reject `openSocket`.
- Missing messages reject through `next()` with a timeout.
- Unexpected close events reject all pending message waiters.
- Assertions fail the test immediately when a protocol response differs from the contract.

## Notes

- Tests use port `0` so they do not collide with a running local relay.
- Timers are shortened to keep the suite fast and deterministic.
- These tests exercise network behavior but not Flutter UI or physical haptics.
