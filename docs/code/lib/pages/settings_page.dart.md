# lib/pages/settings_page.dart

## Purpose

Holds app behavior, detailed device capabilities, platform limitations, local-data reset, and product scope.

## Key behavior

- The app-haptics switch is an app-level control, not a system setting.
- Shows the full asynchronous capability report previously shown on the Compatibility page.
- Displays native warnings when present.
- Lists what the app cannot change and why results vary between devices.
- Reset asks for confirmation, restores defaults, and clears user presets.
- Test duration and output controls live on Home.

## Inputs and outputs

Reads and writes settings and user presets; reads the asynchronous capability report.

## Dependencies

- `flutter_riverpod`
- `lib/constants/app_strings.dart`
- `lib/constants/capability_strings.dart`
- `lib/providers/app_state.dart`
- `lib/widgets/app_widgets.dart`

## Error handling

Capability loading shows a progress indicator; capability failure shows an error card. Reset requires explicit confirmation. Storage is in memory until the persistence stage.
