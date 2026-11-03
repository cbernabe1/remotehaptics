# pubspec.yaml

## Purpose

Declares the Flutter package identity, SDK constraint, runtime dependencies, and development dependencies.

## Current identity

- Package name: `vibration_control`
- Description: in-app haptics laboratory
- Publishing: disabled

## Runtime dependencies

- `flutter`
- `cupertino_icons`
- `flutter_riverpod`
- `shared_preferences`
- `uuid`
- `web_socket_channel`

## Development dependencies

- `flutter_test`
- `flutter_lints`

## Fonts

- `assets/fonts/Manrope-Variable.ttf` is bundled as the `Manrope` family.
- `assets/fonts/OFL.txt` keeps the font license beside the asset.
- The font is applied by `lib/theme/app_theme.dart`.

## Notes

`shared_preferences` is installed for the later persistence stage. The current UI stores settings and presets in memory. New dependencies must be justified in `docs/DECISIONS.md`. `web_socket_channel` exists only for the optional remote-session transport; local haptics remain offline.
