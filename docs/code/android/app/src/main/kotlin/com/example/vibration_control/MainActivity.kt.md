# MainActivity.kt

## Purpose

Android entry activity and native haptics bridge for the Flutter application.

## Key behavior

- Registers `com.example.vibration_control/haptics` after the Flutter engine starts.
- `getCapabilities` reports actuator availability, amplitude support, pattern support, stop support, OS version, and warnings.
- `play` converts request segments into a `VibrationEffect` waveform.
- Amplitude-capable devices use 1-255 amplitudes mapped from the app's 1-100 output level.
- Devices without amplitude control use an on/off waveform, padded with an initial off segment, and emit explicit fallback warnings.
- `stop`, activity pause, and activity destruction cancel active playback.

## Inputs and outputs

- `getCapabilities` takes no arguments and returns a map.
- `play` accepts a request ID, repeat count, and segment list; returns started state, effective mode, warnings, and an optional error code.
- `stop` returns no value.

## Dependencies

- Android `Vibrator`, `VibratorManager`, and `VibrationEffect`
- Flutter `FlutterActivity`, `FlutterEngine`, and `MethodChannel`
- `android.permission.VIBRATE`

## Error handling

Missing actuators and empty requests return typed failure maps. Unexpected playback exceptions are returned as `PLAYBACK_ERROR`.

## Notes

Playback is limited to app-generated vibration. It does not change system-wide intensity or other apps' haptics. Playback always uses normal app haptics.
