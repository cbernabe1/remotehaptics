# test/widget_test.dart

## Purpose

Automated checks for validation rules, three-tab navigation, the Home graph control, and saving presets.

## Coverage

- Valid and invalid duration, strength, and preset names.
- Normalization of out-of-range values.
- Navigation through Home, Remote, and Settings, with no standalone Presets page.
- Dragging the Home vibration graph changes the strength and reports hold start/end.
- Holding the Home graph starts playback, moving changes the live preview strength, and release stops playback.
- Saving a named preset from Home adds it to the preset library.

## Inputs and outputs

Uses `flutter_test` and a Riverpod `ProviderScope`. Tests override the haptics provider with `PreviewVibrationService` so they do not call a real MethodChannel. Each test asserts visible text or validator results.

## Dependencies

- `flutter_test`
- `flutter_riverpod`
- `lib/app.dart`
- `lib/utils/vibration_validator.dart`
- `lib/services/preview_vibration_service.dart`

## Notes

These tests do not prove real haptic behavior. Physical-device tests remain required for native playback. The save-preset dialog avoids a `TextEditingController` so its text field cannot be used after disposal during the dialog exit animation.
