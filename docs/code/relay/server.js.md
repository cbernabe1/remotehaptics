# server.js

## Purpose

A small in-memory WebSocket relay for paired remote haptics sessions. It lets one phone control app-generated haptics on a second phone after the host explicitly approves the connection. It stores no accounts, messages, names, or presets.

## Main entry points

- `createRelayServer(overrides)` creates the HTTP server, WebSocket server, room registry, rate limits, heartbeat, and timers. It returns `listen()` and `close()` helpers for tests and production startup.
- The module starts automatically when run with `node server.js`.

## Protocol

- `create_room` creates a six-digit room and registers the sender as host.
- `join_room` places a controller in a pending state and sends `join_request` to the host.
- `join_decision` accepts or declines the pending controller. Approval moves both phones to an active session.
- `haptic` is accepted only from the active controller and relayed only to the host.
- `haptic_status` is accepted only from the host and relayed only to the controller.
- `leave` closes the sender's room.

## Safety and validation

- Room codes are random six-digit numbers and are never reused while active.
- The host must approve every controller; there is no code-only access.
- The controller role is enforced on all haptic messages.
- Strength must be an integer from 1 to 100.
- Names are trimmed, control characters are removed, and length is capped.
- JSON messages are capped at 4 KB.
- Join and create attempts are rate-limited per IP.
- Rooms expire after 10 minutes while waiting, 60 seconds while awaiting approval, or 30 minutes while active.
- WebSocket ping/pong removes dead clients.

## HTTP endpoints

- `GET /healthz` returns `{ "ok": true, "rooms": <count> }`.
- All other HTTP paths return 404.

## Dependencies

- Node.js 20 or newer.
- `ws` for WebSocket handling.
- Node built-ins for HTTP, crypto, and URLs.

## Error handling

Invalid JSON, unknown message types, missing rooms, role violations, invalid strength, rate limits, full relays, and expired requests return an `error` message with a stable code and a user-safe message. The server does not crash on malformed client input.

## Production notes

- Run behind a TLS-terminating proxy and use a `wss://` public URL.
- Set `TRUST_PROXY=1` only when the proxy is trusted.
- All state is in memory, so a restart ends every session.
