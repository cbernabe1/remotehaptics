# lib/models/vibration_models.dart

## Purpose

Contains immutable models shared by the UI, providers, services, and native bridge.

## Key types

- `VibrationSegment`: one vibration duration, pause, and requested strength.
- `VibrationRequest`: validated playback request with request ID, segments, and repeat count.
- `VibrationPreset`: saved or built-in preset; converts to a request.
- `AppSettings`: default duration, default strength, enabled flag, and selected preset.
- `CapabilityReport`: platform and runtime haptics capabilities.
- `PlaybackResult`: started state, effective mode, warnings, request ID, and error code.
- `PlaybackState`: current UI playback state.
- `BuiltInPresets`: Soft, Normal, Strong, and Double pulse reference effects.

## Rules represented

- Android amplitude is requested as 1-100 percent in the domain.
- A request can calculate its total duration for UI timing.
- Built-in presets are constant and must not be persisted as user data.

## Dependencies

- `uuid` for request and preset identifiers.

## Notes

No model performs platform calls. JSON serialization and persistence will be added in the local-persistence stage.
