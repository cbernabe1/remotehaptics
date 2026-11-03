# test/android_vibration_service_test.dart

## Purpose

Verifies the Dart side of the Android haptics MethodChannel without physical hardware.

## Coverage

- Maps a native capability map into `CapabilityReport`.
- Serializes a `VibrationRequest` into native arguments and maps the result.
- Confirms serialized play arguments do not include a channel selector.
- Sends the stop command.

## Inputs and outputs

Registers a mock handler on `com.example.vibration_control/haptics`, records `MethodCall` objects, and asserts returned domain models and serialized values.

## Dependencies

- `flutter_test`
- `flutter/services.dart`
- `lib/services/android_vibration_service.dart`
- `lib/models/vibration_models.dart`

## Notes

These tests prove channel mapping only. They do not prove that a phone's actuator actually vibrates. Playback coverage is limited to normal app haptics.
