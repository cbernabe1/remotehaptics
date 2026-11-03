# lib/config/remote_config.dart

## Purpose

Holds compile-time defaults and safety limits for remote haptics sessions.

## Key values

- `defaultRelayUrl`: uses `--dart-define=RELAY_URL=...` when provided; otherwise `ws://localhost:8080/ws` on web/desktop and `ws://10.0.2.2:8080/ws` on Android.
- `maxHoldMs`: 5000 ms maximum remote hold.
- `approvalTimeoutMs`: documents the relay's 60-second approval window.
- `roomLifetimeMs`: documents the 10-minute waiting-room lifetime.
- `defaultDisplayName`: fallback label shown to the paired phone.

## Notes

`10.0.2.2` works for the Android emulator only. A physical phone must use the computer's LAN address or a deployed `wss://` relay URL. The Remote page lets the user edit the relay URL at runtime.

## Dependencies

- `flutter/foundation.dart` for `kIsWeb` and `defaultTargetPlatform`.
