# lib/constants/platform_strings.dart

## Purpose

Centralizes platform names and platform-specific preview text used by services and pages.

## Key constants

- Names: `android`, `ios`, `webPreview`, `chrome`, `unknown`.
- Preview warnings: `previewOnlyWarning`, `previewFutureWarning`, `simulatedPlayback`.

## Inputs and outputs

Exposes compile-time `String` constants only. No runtime state or platform calls.

## Usage

Use these constants instead of hardcoded `'Android'`, `'Chrome'`, or platform-specific warning copy.

## Notes

Native Kotlin still owns native-only messages returned over the MethodChannel. These constants cover Dart-side display text.
