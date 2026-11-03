# lib/app.dart

## Purpose

Defines the Material 3 application shell and the three-page navigation.

## Key classes

- `VibrationControlApp`: applies the shared light/dark themes and app title.
- `AppShell`: watches the selected tab and displays the matching page in an `IndexedStack`.
- `NavigationBar` destinations: Home, Remote, and Settings.

## Inputs and output

The shell reads `selectedTabProvider` and calls `SelectedTabController.select` when the user changes tabs. The `IndexedStack` preserves each page's state while switching tabs.

## Dependencies

- `flutter_riverpod`
- `HomePage`, `RemotePage`, `SettingsPage`
- `lib/constants/app_strings.dart`
- `lib/providers/app_state.dart`
- `lib/theme/app_theme.dart`

## Non-obvious behavior

Each page owns its own `Scaffold` and `AppBar`; the shell provides the floating rounded navigation bar and shared page stack. The Presets page was removed; the preset library lives on Home. Remote adds pairing over a WebSocket relay. The navigation bar sits inside a rounded container with a soft shadow.
