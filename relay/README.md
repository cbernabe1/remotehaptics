# Remote haptics relay

Small WebSocket relay for paired remote sessions. It does not store accounts, presets, names, or messages. It keeps rooms in memory and deletes them when a phone leaves or the room expires.

## Protocol

The relay accepts JSON messages at `/ws`. A room has one host and at most one controller.

1. Host sends `create_room` and receives `room_created` with a six-digit code.
2. Controller sends `join_room` with that code.
3. Host receives `join_request` and sends `join_decision`.
4. On approval, both phones receive `session_started`.
5. Controller sends `haptic` with `start`, `update`, or `stop`.
6. Host sends `haptic_status` so the controller can show remote playback state.

Haptic messages are relayed only while the room is active and only from the paired controller.

## Run locally

```powershell
cd relay
npm.cmd install
npm.cmd start
```

The server listens on `ws://0.0.0.0:8080/ws` and exposes `GET /healthz`.

## Use from the app

- Chrome on the same computer: `ws://localhost:8080/ws`
- Android emulator: `ws://10.0.2.2:8080/ws`
- Physical phone on the same Wi-Fi: `ws://<computer-LAN-IP>:8080/ws`
- Internet: deploy the relay and use `wss://<your-domain>/ws`

Both phones must use the same relay URL. The URL is entered on the Remote page.

## Deploy

The included `Dockerfile` is suitable for Render, Fly.io, Railway, or any container host.

```powershell
docker build -t vibration-relay .
docker run --rm -p 8080:8080 vibration-relay
```

Set these environment variables in production:

| Variable | Default | Purpose |
|---|---|---|
| `PORT` | `8080` | HTTP/WebSocket port |
| `HOST` | `0.0.0.0` | Listen address |
| `TRUST_PROXY` | unset | Set to `1` when a trusted proxy supplies `X-Forwarded-For` |
| `MAX_ROOMS` | `1000` | Maximum concurrent rooms |

Use a TLS-terminating proxy so the public URL is `wss://`. Do not expose the plain `ws://` server directly to the internet.

## Test

```powershell
cd relay
npm.cmd test
```

## Limits

- Six-digit room codes are short-lived and require host approval.
- Join and create attempts are rate-limited per IP.
- Waiting rooms expire after 10 minutes, approvals after 60 seconds, and active sessions after 30 minutes.
- Messages are capped at 4 KB.
- The relay is in-memory only; restarting it ends every session.
