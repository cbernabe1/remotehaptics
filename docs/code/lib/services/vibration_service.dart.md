# lib/services/vibration_service.dart

## Purpose

Defines the platform-neutral service contract for capability detection, playback, and cancellation.

## Contract

- `getCapabilities()` returns a `CapabilityReport`.
- `play(VibrationRequest)` returns a `PlaybackResult`.
- `stop()` cancels active playback.

## Dependencies

- `lib/models/vibration_models.dart`

## Error handling

Implementations may throw platform or bridge errors. Controllers catch them and convert them to user-safe playback state.

## Notes

Android uses `AndroidVibrationService`. Web, desktop, and iOS currently use `PreviewVibrationService` until iOS native haptics are implemented.
