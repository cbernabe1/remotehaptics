# relay/Dockerfile

## Purpose

Builds a small production container for the paired-haptics WebSocket relay.

## Key steps

- Uses `node:24-alpine` as the runtime image.
- Sets `/app` as the working directory.
- Copies only `package.json` and the lock file, then runs `npm ci --omit=dev` for a deterministic production install.
- Copies `server.js` into the image.
- Defaults `HOST` to `0.0.0.0` and `PORT` to `8080`, exposes port `8080`, and starts the relay with `node server.js`.

## Inputs and outputs

- Input: `relay/package.json`, `relay/package-lock.json`, and `relay/server.js`.
- Output: an image that serves `/ws` and `/healthz` until stopped.

## Dependencies

- Node 24 Alpine base image.
- The `ws` dependency installed from the lock file.
- A container host or platform that supports WebSocket traffic and TLS termination.

## Error handling

The container exits if dependency installation or server startup fails. Deployment health checks should target `/healthz`.

## Notes

The Dockerfile does not terminate TLS. Production deployments must place it behind a TLS-capable reverse proxy or platform load balancer and expose a `wss://` URL.
