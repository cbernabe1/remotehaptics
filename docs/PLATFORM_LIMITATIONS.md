# Platform Limitations

> **Status:** Approved planning baseline, 2026-10-30.
> **Source:** `VIBRATION_CONTROL_PLAN.md`, Sections 2, 3, 4, and 19.
> **Rule:** Platform claims must be verified against official documentation and physical devices before release.

## 1. Product Boundary

The application controls haptics that it generates itself while it is in the foreground. Paired remote mode lets a second phone request those same in-app effects, but only after the host approves and while both apps remain active.

The application does not control:

- global Android or iOS vibration intensity;
- call, SMS, alarm, or third-party notification vibration;
- another application's haptics;
- the physical motor directly;
- hardware beyond its documented maximum.

This boundary must appear in the UI, Settings, release notes, and any store listing.

## 2. Capability Definitions

| Label | Meaning |
|---|---|
| Fully supported | Available through public APIs, subject to hardware and user settings. |
| Supported with limitations | Available but restricted by platform, hardware, lifecycle, or fallback behavior. |
| Device-dependent | Behavior varies by model, OEM implementation, settings, or capability flags. |
| Native implementation required | Flutter built-in APIs are insufficient. |
| Special permission required | Not usable by an ordinary third-party application. |
| Not available | No supported public API for an ordinary third-party application. |

## 3. Android Limitations

### Confirmed behavior

- `Vibrator` and `VibratorManager` expose vibration hardware.
- API 31+ prefers `VibratorManager.getDefaultVibrator()`.
- `hasVibrator()` reports whether a vibrator exists.
- `hasAmplitudeControl()` reports whether amplitude can vary.
- `VibrationEffect.createOneShot(durationMs, amplitude)` accepts amplitude 1-255 or `DEFAULT_AMPLITUDE`.
- `VibrationEffect.createWaveform(timings, amplitudes, repeat)` supports multi-segment patterns.
- Waveform timings alternate off and on; the first timing is an off duration.
- If amplitude control is unavailable, non-zero amplitude values become full strength.
- Playing an effect requires the normal `VIBRATE` manifest permission.
- Background vibration is restricted to attentional usages such as alarms, ringtones, and notifications.
- API 33+ uses `VibrationAttributes`; older code uses `AudioAttributes`.
- `USAGE_TOUCH` or a foreground-feedback usage is more truthful than `USAGE_ALARM` for this application.
- `USAGE_ALARM` may use alarm vibration intensity and bypass touch-feedback scaling; OEM behavior varies.
- `HapticFeedbackConstants` and `View.performHapticFeedback()` provide platform-consistent UI feedback but no arbitrary duration or amplitude.

### Restrictions

- No supported public API lets an ordinary app change global notification vibration intensity.
- `WRITE_SETTINGS` is a special user-granted capability, but it does not provide a reliable cross-device vibration-intensity API.
- Android documentation states that changing `Settings.System.VIBRATE_ON` internally does not change vibration behavior.
- OEMs may scale, suppress, or reinterpret amplitude.
- `hasAmplitudeControl()` is a capability signal, not a guarantee of linear perceived strength.
- Emulators normally cannot reproduce real vibration strength.
- Android 16+ `VibrationEffect.Builder` composition is optional and not required for the MVP.

### MVP implementation rules

- Use API 26 waveform APIs for the stable baseline.
- Never claim amplitude support from the OS version alone.
- Disable or explain amplitude controls when `hasAmplitudeControl()` is false.
- Keep haptic playback in the foreground.
- Stop playback when the app is backgrounded.
- Do not use `USAGE_ALARM` for ordinary in-app effects. This app uses normal app haptics only.

## 4. iOS Limitations

### Confirmed behavior

- Core Haptics is available from iOS 13 on haptic-capable iPhones starting with iPhone 8.
- iPad, iPod touch, and Apple Vision Pro do not support Core Haptics haptics.
- `CHHapticEngine.capabilitiesForHardware().supportsHaptics` is the runtime check.
- Core Haptics can play transient and continuous events in custom patterns.
- `hapticIntensity` and `hapticSharpness` are normalized from 0.0 to 1.0.
- `CHHapticAdvancedPatternPlayer` supports stop, pause, seek, and loop.
- Fire-and-forget `playPattern(from:)` cannot be stopped.
- The engine stops when the app is suspended, backgrounded, or interrupted.
- The engine must be restarted before the next playback.
- `UIImpactFeedbackGenerator.impactOccurred(intensity:)` is available from iOS 13 with intensity 0.0-1.0 but no arbitrary duration or multi-segment pattern.
- The iOS Simulator has no haptic interface.

### Restrictions

- No documented public API reads or changes Sounds & Haptics settings.
- No public API changes call, SMS, alarm, or third-party notification vibration.
- No custom notification patterns comparable to foreground Core Haptics.
- Background haptic playback is not available for this use case.
- The system may override or suppress haptic requests.
- The app cannot deep-link directly to Sounds & Haptics through a documented public API; it can only guide the user.

### MVP implementation rules

- Check `supportsHaptics` at runtime.
- Use Core Haptics for supported iPhones.
- Use an advanced player when stop or interruption handling is needed.
- Restart the engine after interruption or foreground return.
- Treat the simulator as a UI test target only.
- Never claim iOS haptics work because the Flutter UI compiles.

## 5. Flutter Limitations

Flutter's built-in `HapticFeedback` is a convenience API and is not suitable for precise duration, amplitude, or pattern control.

- `HapticFeedback.vibrate()` maps to platform-specific feedback.
- `lightImpact`, `mediumImpact`, and `heavyImpact` map to platform constants or feedback generators.
- There is no duration, amplitude, waveform, or repeat parameter.

The production implementation therefore uses a native `MethodChannel`.

## 6. Third-Party Package Assessment

The `vibration` package version 3.2.1 was reviewed as a potential shortcut.

Concerns:

- Android uses `AudioAttributes.USAGE_ALARM` for all vibrations.
- Some iOS failures are printed rather than returned as structured errors.
- Capability reporting is incomplete for a diagnostics-oriented application.
- It is maintained but effectively single-maintainer, with an unverified pub.dev uploader.

Decision: do not use the package as the architectural core. It is acceptable only for a throwaway spike.

## 7. Remote Mode Limitations

- Both phones must run this app and connect to the same relay.
- The host must approve every controller session.
- The apps must stay in the foreground; hiding either app ends the session.
- Remote playback is capped at 5 seconds per hold and uses best-effort live transport.
- No message history, room history, accounts, or identity data are persisted.
- The relay is in-memory; a restart or all-peer disconnect ends sessions.
- Rooms expire: 10 minutes waiting, 60 seconds for approval, 30 minutes active.
- A public deployment must use TLS (`wss://`); plain `ws://` is for local/LAN testing only.
- Network latency and relay location affect responsiveness.
- Remote mode does not bypass any Android/iOS haptic or background restrictions described above.

## 8. Compatibility Matrix

| Capability | Android | iOS | Flutter route | Overall result |
|---|---|---|---|---|
| Detect actuator | Supported, device-dependent | Supported with limits | Native bridge | Android full; iOS limited |
| Detect amplitude/intensity capability | `hasAmplitudeControl()` | `supportsHaptics` plus parameter attributes | Native bridge | Device-dependent |
| Fixed-duration vibration | `VibrationEffect` | Core Haptics continuous events or fixed fallback | Native bridge | Limited overall |
| Amplitude/intensity adjustment | 1-255 where supported | 0.0-1.0 where supported | Native bridge | Device-dependent |
| Multi-segment patterns | Waveform | Core Haptics events | Native bridge | Limited overall |
| Stop/cancel | `Vibrator.cancel()` | Advanced player or engine stop | Native bridge | Limited overall |
| Predefined/system haptics | API 29+ effects | UIKit feedback generators | Flutter or native | Device-dependent |
| UI control haptics | Haptic feedback constants | UIKit generators | Flutter `HapticFeedback` | Device-dependent |
| Own notification vibration | Own notification channel only | Not available | Native Android only | Limited Android; unavailable iOS |
| Call/SMS/alarm/third-party vibration | Not available | Not available | None | Not available |
| Global system vibration intensity | Not available | Not available | None | Not available |
| Direct motor control or overdrive | Root or privileged only | Not available | None | Not available |
| Background haptic playback | Attentional usages only | Engine suspends | None | Not suitable |
| Read user haptic settings | Partial and OEM-dependent | Not available | Native best effort | Limited Android; unavailable iOS |
| Save/load presets locally | Supported | Supported | Flutter | Fully supported |
| Import/export presets | Supported locally | Supported locally | Flutter file APIs | Post-MVP |
| Compatibility report | Runtime checks only | `supportsHaptics` and attributes | Native bridge | Limited overall |
| Paired remote haptics | Supported with limitations | Supported with limitations | Flutter WebSocket + relay | Foreground, approved sessions only |
| Remote background control | Not available | Not available | None | Session ends when app hides |

## 9. Unverified Claims Requiring Device Tests

- Whether iOS Core Haptics is suppressed when System Haptics is disabled.
- Whether Android OEM skins suppress or scale `USAGE_TOUCH` effects when touch feedback is disabled.
- Exact perceived response curves on Pixel, Samsung, Xiaomi, and other devices.
- Low Power Mode and battery-saver behavior.
- iOS silent-mode interaction with haptics-only patterns.
- Behavior of the `vibration` package, if used for a spike, on target devices.
- Actual device capability flags for the available Android and iPhone test hardware.

## 10. Required User-Facing Disclosure

The application must state:

> This app adjusts haptic effects generated by this app. It cannot change your phone's system-wide vibration intensity, call vibration, notification vibration, or other apps' haptics.

The app must also state that perceived strength varies by device, system settings, and hardware, and that the output level is not a linear loudness control.

## 11. Device Verification Log

Device-specific results are recorded in `DEVICE_TEST_LOG.md`. This document must be updated after every physical-device test.
