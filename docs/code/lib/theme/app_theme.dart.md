# lib/theme/app_theme.dart

## Purpose

Defines the app's light and dark Material 3 themes, color palette, typography, and component styling.

## Key behavior

- Uses a violet primary, mint secondary, and coral tertiary palette to suggest energy, touch, and pulse feedback.
- Builds separate light and dark `ColorScheme` values with custom surface and container colors.
- Applies the bundled Manrope font through the text theme and component text styles.
- Styles cards, rounded icon containers, navigation, chips, inputs, dialogs, snackbars, buttons, dividers, and progress indicators consistently.
- Keeps the navigation bar rounded and elevated with a soft shadow.

## Inputs and outputs

- `AppTheme.light()` returns the light `ThemeData`.
- `AppTheme.dark()` returns the dark `ThemeData`.
- `AppTheme.fontFamily` exposes the shared font family name.

## Dependencies

- `flutter/material.dart`
- `assets/fonts/Manrope-Variable.ttf`, registered in `pubspec.yaml`

## Notes

Manrope is distributed under the SIL Open Font License; the license text is stored beside the font asset. The palette is intentionally distinct from the previous indigo seed-only theme.
