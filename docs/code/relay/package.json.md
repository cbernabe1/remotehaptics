# relay/package.json

## Purpose

Defines the Node.js relay package, its runtime dependency, and developer commands.

## Key fields

- `private: true` prevents accidental publication to npm.
- `type: module` enables ES module imports in `server.js` and tests.
- `engines.node >= 20` documents the minimum runtime; the current host uses Node 24.
- `scripts.start` runs `node server.js`.
- `scripts.test` runs all relay integration tests with Node's built-in test runner.
- `dependencies.ws` provides the WebSocket server and client implementation.

## Inputs and outputs

- Input: npm install/test/start commands.
- Output: installed dependencies in `relay/node_modules` and test/start process behavior.

## Dependencies

- `ws` is the only runtime dependency.
- `npm.cmd` must be used on this Windows host because the PowerShell `npm.ps1` shim is blocked by execution policy.

## Error handling

npm reports dependency installation or script failures through the console and a non-zero exit code. The package has no application-level error handling.

## Notes

`package-lock.json` should be committed with this file so deployments use deterministic dependency versions.
