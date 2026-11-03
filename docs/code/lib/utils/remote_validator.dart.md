# lib/utils/remote_validator.dart

## Purpose

Validates user-entered remote-session data before connecting.

## Rules

- Room code: exactly six digits after removing whitespace.
- Relay URL: `ws://` or `wss://` with a non-empty host.
- Display name: non-empty, at most 24 characters, no control characters.
- `normalizeCode`: removes all whitespace from the code.

## Inputs and outputs

Each `validate...` method returns `null` for valid input or a user-facing error string. The Remote page displays the returned error in a snackbar.
