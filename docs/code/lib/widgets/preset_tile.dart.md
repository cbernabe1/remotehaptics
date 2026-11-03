# lib/widgets/preset_tile.dart

## Purpose

Shared list row for built-in and saved presets on Home.

## Key behavior

- Shows preset name, total duration, segment count, and first-segment strength.
- Uses a compact icon that distinguishes single and multi-segment effects.
- Provides a play button and, when supplied, a delete button.

## Inputs and outputs

- `preset`: the `VibrationPreset` to display.
- `onPlay`: preview callback.
- `onDelete`: optional delete callback; hidden when null.

## Dependencies

- `flutter/material.dart`
- `lib/models/vibration_models.dart`

## Notes

The widget is presentation-only; Home owns playback and deletion behavior. The leading icon uses the secondary mint container from the shared theme.
