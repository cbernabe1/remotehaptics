# Device Test Log

> **Status:** Physical Android device previously detected; native playback works and maximum normal touch output is weak, confirming a practical hardware ceiling. The phone is currently disconnected. Paired remote haptics still need two-device validation.
> **Rule:** Emulator and simulator results are not accepted as proof of haptic strength.

## 1. Inventory

| ID | Device | Platform | OS | Actuator | Amplitude / Core Haptics | Status | Notes |
|---|---|---|---|---|---|---|---|
| DEV-01 | Current development host | Windows | Windows 11 25H2, build 10.0.26200.9711 | Not applicable | Not applicable | Detected | Build host only; not a haptics target |
| DEV-02 | M2007J20CG | Android | Android 12, API 31 | Confirmed | Amplitude control supported | Last seen as `d1ec8596`; currently disconnected | Native playback confirmed; strength still weak |
| DEV-03 | iPhone 8+ | iOS | Pending, must be 13.0+ | Pending | Core Haptics expected | Available per user; not connected | Requires macOS/Xcode and a physical connection |
| DEV-04 | Chrome 156.0.8078.48 | Web | Windows | Not applicable | Not applicable | Detected | Not a haptics target |
| DEV-05 | Edge 156.0.4314.50 | Web | Windows | Not applicable | Not applicable | Detected | Not a haptics target |
| DEV-06 | Second Android device | Android | Pending | Pending | Non-amplitude preferred | Not confirmed | Required to validate unsupported-amplitude fallback |

## 2. Required Device Details

Record the following for each physical device before haptic testing:

- manufacturer and model;
- Android or iOS version;
- actuator availability;
- `hasAmplitudeControl()` result on Android;
- `supportsHaptics` result on iOS;
- system haptics or touch-feedback setting;
- power-saving mode;
- app build number;
- test date and tester.

## 3. Test Results

| Test | Device | Build | Result | Evidence / notes |
|---|---|---|---|---|
| Capability detection | M2007J20CG | `1.0.0+1` debug | Implemented, not run | Stage 5 |
| Safe test pulse | M2007J20CG | `1.0.0+1` debug | Passed; weak at 100% | Native playback works. App requests amplitude 1.0; `dumpsys vibrator_manager` reports `Usage=TOUCH`. Still weak after `mHapticFeedbackIntensity` was raised to HIGH. |
| Stop playback | Pending | Pending | Not run | Stage 6 |
| Duration validation | Pending | Pending | Not run | Stage 6 |
| Output-level mapping | Pending | Pending | Not run | Stage 7 |
| Unsupported amplitude behavior | Pending | Pending | Not run | Stage 7 |
| Built-in presets | Pending | Pending | Not run | Stage 4-6 |
| Save and reload preset | Pending | Pending | Not run | Stage 9 |
| Background stops playback | Pending | Pending | Not run | Stage 6/10 |
| Interruption recovery | Pending | Pending | Not run | Stage 10 |
| Rapid repeated taps | Pending | Pending | Not run | Stage 10 |
| System haptics disabled | Pending | Pending | Not run | Stage 10 |
| Low Power Mode | Pending | Pending | Not run | Stage 10 |
| Airplane mode | Pending | Pending | Not run | Stage 10 |
| Remote host approval | Two phones | Pending | Not run | Stage 7A |
| Remote live haptics | Two phones | Pending | Not run | Stage 7A |
| Remote stop/disconnect | Two phones | Pending | Not run | Stage 7A |
| Remote background teardown | Two phones | Pending | Not run | Stage 7A |
| Accessibility pass | Pending | Pending | Not run | Stage 10 |
| Release build install | Pending | Pending | Not run | Stage 12 |

## 4. Observations

### 2026-10-30

- `flutter devices` detected only Windows, Chrome, and Edge.
- Android SDK 36.0.0, platform android-37.0, build-tools 36.0.0, cmdline-tools, NDK 28.2.13676358, CMake 3.22.1, and licenses are now configured.
- `M2007J20CG` (`d1ec8596`, Android 12 / API 31, arm64) is connected and listed by `flutter devices`.
- `flutter build apk --debug` succeeds.
- `adb install -r build\app\outputs\flutter-apk\app-debug.apk` initially failed with `INSTALL_FAILED_USER_RESTRICTED`; it now succeeds after phone-side authorization.
- Alternates also fail: `--no-streaming`, explicit `--user 0`, and `adb push` plus `pm install`.
- The phone is MIUI `V140` on Android 12 and has a second space (`XSpace`, user 999) running; the main owner is user 0.
- Debug APK copied to `/sdcard/Download/vibration-control-debug.apk` for a manual-install fallback.
- Native Android capability, waveform playback, stop, and app-background cancellation implemented in `MainActivity.kt`.
- `android.permission.VIBRATE` added.
- Updated debug APK built and copied to `/sdcard/Download/vibration-control-debug.apk`.
- User confirmed native playback works on `M2007J20CG`.
- User reported that 100% output still feels weak.
- `dumpsys vibrator_manager` shows the app's effects at amplitude `1.0` with `Usage=TOUCH`; the phone reports `mHapticFeedbackIntensity=MEDIUM`.
- Next check: raise MIUI touch-feedback vibration intensity, charge above 20%, and retest at 5000 ms / 100%.
- ADB changed `haptic_feedback_intensity` from the default MEDIUM to HIGH (`3`) and enabled `haptic_feedback_enabled`; the system now reports `mHapticFeedbackIntensity=HIGH`.
- User retested and still reports weak output at 100%, so touch-intensity scaling is not the only cause.
- Latest APK pushed to `/sdcard/Download/vibration-control-debug.apk`.
- `adb install -r build\app\outputs\flutter-apk\app-debug.apk` now succeeds; the MIUI USB-install blocker is resolved.
- Latest build installed and launched on the phone.
- Conclusion: the app reaches the public Android maximum and no supported API path produces stronger output on this device. Further strength work would require unsafe/root-level motor control and is out of scope.
- The three-page UI with hold-to-vibrate graph, refreshed theme, and remote pairing passes `flutter analyze`, `flutter test` (14 tests), `flutter build web`, and `flutter build apk --debug`. The new APK has not been installed because the phone is disconnected.
- The Node relay's 4 protocol tests pass locally, and a temporary Flutter-to-relay round-trip test passed against the local server.
- Remote control has not been validated on two physical phones yet. It still needs a deployed `wss://` relay, host approval, and live playback testing.
- The project was restructured to `lib/pages`, `lib/models`, `lib/providers`, `lib/services`, `lib/utils`, and `lib/widgets`. The restructured APK built successfully, but the phone disconnected before reinstall.
- Flutter web is enabled and the MVP UI builds successfully for Chrome.
- Chrome preview uses simulated playback and is not a haptic device result.
- No iOS device was connected; iOS cannot be built from the current Windows host.

## 5. Update Rules

- Append a new dated observation for every test session.
- Never overwrite a failed result.
- Record the exact build number.
- Record whether system haptics, touch feedback, silent mode, or low-power mode was enabled.
- Update `docs/PLATFORM_LIMITATIONS.md` when a platform assumption is confirmed or contradicted.
