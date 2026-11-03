# lib/services/preview_vibration_service.dart

## Purpose

Implements the haptics contract for the Chrome UI preview.

## Behavior

- `getCapabilities()` waits briefly, then reports a simulated amplitude-capable environment with explicit preview warnings.
- `play()` accepts a request and returns a simulated amplitude-mode result.
- `stop()` completes after a short simulated delay.

## Inputs and outputs

Consumes `VibrationRequest` and returns `CapabilityReport` or `PlaybackResult`. No vibration hardware is touched.

## Dependencies

- `lib/constants/platform_strings.dart`
- `lib/models/vibration_models.dart`
- `lib/services/vibration_service.dart`

## Error handling

The preview service does not throw under normal use. Controllers still catch errors so the screen remains usable.

## Non-obvious behavior

The simulated capability is intentional so the UI can be exercised in Chrome or on non-Android hosts. The warnings and `Platform: Web preview` label prevent it from being mistaken for a real device report. Android uses `AndroidVibrationService` instead.
