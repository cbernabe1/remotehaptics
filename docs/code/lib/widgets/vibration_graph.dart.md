# lib/widgets/vibration_graph.dart

## Purpose

Provides a tactile, graph-style strength control for Home.

## Key behavior

- Renders a rounded waveform panel with a grid, amplitude-scaled wave, level handle, and a primary-to-mint gradient.
- Reports hold start on pointer down, updates strength while the finger moves, and reports hold end on pointer up or cancel.
- Calls `onChanged` for every strength update so Home can refresh the setting and live preview.
- `onHoldStart` and `onHoldEnd` let Home start and stop playback around the touch duration.
- `enabled` disables gestures and accessibility actions when output control is unavailable.
- Tracks one active pointer so multi-touch cannot start overlapping holds.
- Exposes slider semantics with value, increased value, decreased value, and increase/decrease actions.

## Inputs and outputs

- `value`: current 1-100 strength.
- `onChanged`: receives the new strength during interaction.
- `onHoldStart`: called when the user touches the graph.
- `onHoldEnd`: called when the touch ends or is cancelled.
- `enabled`: controls whether interaction is allowed.

## Dependencies

- `dart:math`
- `flutter/material.dart`

## Notes

The graph visualizes requested amplitude over time. It is not a frequency equalizer; Android haptics expose amplitude over time, not adjustable frequency bands. Pointer moves are read directly by a `Listener` so strength still updates inside a scrolling page.
