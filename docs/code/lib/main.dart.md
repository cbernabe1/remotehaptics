# lib/main.dart

## Purpose

Application entry point. It installs a Riverpod `ProviderScope` and starts the Flutter app.

## Flow

- `main()` calls `runApp`.
- `ProviderScope` supplies shared state and dependency overrides for the widget tree.
- `VibrationControlApp` is the root widget from `lib/app.dart`.

## Dependencies

- `flutter/material.dart`
- `flutter_riverpod`
- `lib/app.dart`

## Notes

There is no asynchronous bootstrap or native initialization yet. Future service initialization must not block the first frame.
