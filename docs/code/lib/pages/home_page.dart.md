# lib/pages/home_page.dart

## Purpose

Primary screen for shaping a vibration pulse and browsing the preset library.

## Key behavior

- Watches capability, playback, settings, and user-preset providers.
- Shows a graph-based strength control instead of linear sliders.
- Pressing the graph starts vibration immediately; moving vertically updates the requested output and restarts the hold preview after a short debounce; releasing stops it.
- The vibration duration matches the hold time, capped at the 5-second safety limit.
- Duration chips select the length used by Play test and saved presets.
- Play/Stop uses the normal app channel only.
- Save as preset stores the current strength and duration as an in-memory user preset.
- Lists built-in presets and saved presets; each row can be previewed, and saved presets can be deleted.
- Shows a preview notice in Chrome simulation mode.
- Shows a remote-session banner with an Open action whenever a host or controller session is active.
- Shows a compact capability failure message if the native check fails.

## Inputs and outputs

Reads `CapabilityReport`, `PlaybackState`, `AppSettings`, and the user preset list. Writes default strength/duration, playback requests, and user presets. A stopwatch and timers track the graph hold and enforce the 5-second cap.

## Dependencies

- `flutter_riverpod`
- `uuid`
- `lib/constants/app_strings.dart`
- `lib/models/vibration_models.dart`
- `lib/models/remote_models.dart`
- `lib/providers/app_state.dart`
- `lib/providers/remote_control_controller.dart`
- `lib/utils/vibration_validator.dart`
- `lib/widgets/app_widgets.dart`
- `lib/widgets/preset_tile.dart`
- `lib/widgets/vibration_graph.dart`

## Error handling

Invalid preset names show a snackbar. If capability loading fails, the strength card explains that preview is disabled instead of crashing. The graph is disabled when the environment does not report amplitude or intensity control.
