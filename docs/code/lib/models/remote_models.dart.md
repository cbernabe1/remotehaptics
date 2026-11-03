# lib/models/remote_models.dart

## Purpose

Defines the client-side domain model and wire-event parser for paired remote haptics sessions.

## Key types

- `RemoteRole`: host or controller.
- `RemotePhase`: idle, connecting, waiting for a room, awaiting approval, active, ended, or error.
- `RemoteHapticAction`: start, update, or stop.
- `RemoteState`: immutable UI state containing phase, role, room code, peer name, message, strength, remote playing status, relay URL, and display name.
- Sealed `RemoteEvent` classes: room created, join waiting, join request, decline/cancel, session started, haptic command, haptic status, peer left, session ended, server error, and disconnect.
- `parseRemoteEvent`: converts a decoded JSON map into a typed event. Unknown or malformed messages return `null`.

## Inputs and outputs

The service layer calls `parseRemoteEvent`. The controller and UI consume `RemoteEvent` and `RemoteState`. This file has no Flutter widget or platform dependencies.

## Error handling

Parsing is defensive: missing roles, unknown types, and missing fields return `null` or safe fallback text instead of throwing.
