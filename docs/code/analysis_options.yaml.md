# analysis_options.yaml

## Purpose

Configures Dart static analysis and Flutter lint rules.

## Current settings

- Includes `package:flutter_lints/flutter.yaml`.
- Excludes `build/**`, `android/**`, `ios/**`, and `web/**`.

## Dependencies

- `flutter_lints`

## Notes

`flutter analyze` must remain clean before a stage is considered complete. Native and generated platform files are excluded because they are validated by their own toolchains.
