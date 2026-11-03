# lib/services/android_vibration_service.dart

## Purpose

Adapts the Dart haptics contract to the Android native MethodChannel implementation.

## Key behavior

- Uses the channel `com.example.vibration_control/haptics`.
- `getCapabilities()` reads the native actuator, amplitude, pattern, stop, and warning report.
- `play()` serializes request IDs, repeat count, and segments to the native side.
- `stop()` sends a cancellation command.
- Native mode strings map to the `PlaybackMode` enum.

## Inputs and outputs

Consumes `VibrationRequest` values from the domain layer. Returns `CapabilityReport` and `PlaybackResult` values. Throws `PlatformException` when the native bridge fails; the playback controller converts that into a user-facing message.

## Dependencies

- `flutter/services.dart`
- `lib/constants/platform_strings.dart`
- `lib/models/vibration_models.dart`
- `lib/services/vibration_service.dart`

## Notes

The native implementation is Android-only. Other platforms still use the preview service. Native unit tests mock the MethodChannel; physical-device behavior must still be validated. No channel selector is sent; all playback uses normal app haptics.
