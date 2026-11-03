# lib/utils/vibration_validator.dart

## Purpose

Provides pure validation and normalization rules for duration, output strength, and preset names.

## Key behavior

- Duration must be 20-5000 ms.
- Output strength must be 1-100 percent.
- Preset names are trimmed and limited to 40 characters.
- `normalizeDuration` and `normalizeStrength` clamp out-of-range numbers.

## Inputs and outputs

Each validation method accepts a value and returns `null` when valid or an actionable message when invalid. Normalization returns a clamped integer.

## Dependencies

None.

## Error handling

Validation does not throw. Callers decide whether to block input or show the returned message.

## Notes

These rules are duplicated conceptually in native code later; both layers must validate before playing a request.
