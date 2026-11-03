# Project Progress

> **Last updated:** 2026-11-01.
> **Current stage:** Stage 7 complete; paired remote haptics added over a WebSocket relay. Local and remote UI are awaiting physical-device validation.
> **Overall status:** MVP UI runs in Chrome with simulated haptics. Android native playback is implemented and confirmed on the M2007J20CG. The app reaches maximum amplitude, but normal touch output still feels weak. This is the practical device/hardware ceiling; further strength changes are out of scope.

## 1. Completed

- Planning deliverable approved on 2026-10-30.
- Scope fixed as an in-app haptics laboratory.
- Android-first strategy agreed.
- Smaller MVP agreed; full pattern editor deferred.
- Android 8 / API 26 and iOS 13 minimums agreed.
- Riverpod and SharedPreferences agreed.
- Internal APK/TestFlight distribution agreed.
- Working name and placeholder identifier agreed.
- Physical Android and iPhone 8+ test access confirmed.
- Baseline accessibility scope agreed.
- Stage 1 planning documents created.
- Android Studio 2026.2.2.8 installed.
- Android SDK 36.0.0, platform `android-37.0`, build-tools 36.0.0, cmdline-tools, and platform tools installed.
- Android SDK licenses accepted.
- Android NDK `28.2.13676358`, CMake 3.22.1, and SDK platforms 35/36 installed.
- `flutter doctor` reports a healthy Android toolchain.
- Physical Android device detected: `M2007J20CG`, Android 12 (API 31), `d1ec8596`.
- Stage 3 baseline created for the web preview:
  - Dart package renamed to `vibration_control`.
  - Android namespace/application ID and iOS bundle ID set to `com.example.vibration_control`.
  - Android `minSdk` set to 26.
  - Riverpod, SharedPreferences, and UUID dependencies added.
  - Web target added for Chrome preview.
  - Smoke test replaced with validator and navigation tests.
  - Android debug APK build verified after installing NDK 28.2.13676358.
- Stage 4 MVP UI implemented:
  - Three tabs: Home, Remote, and Settings.
  - Home owns the graph strength control, duration chips, preview, save-preset flow, and preset library.
  - Settings owns app behavior, the detailed capability report, limitations, reset, and about.
  - Chrome preview service with simulated playback.
  - In-memory settings and user presets.
  - Playback guard when app haptics are disabled.
  - Preview and platform-limitation messaging.
- Android native haptics implemented:
  - `AndroidVibrationService` MethodChannel adapter.
  - Kotlin `MainActivity` capability, waveform playback, stop, and app-background cancellation.
  - `android.permission.VIBRATE`.
  - 1-100 output mapped to Android 1-255 amplitudes when supported.
  - On/off fallback, initial off-segment padding, and explicit warnings when amplitude control is unavailable.
- Tests cover Dart-to-native capability mapping, play serialization without a channel selector, stop, validation, Home/Remote/Settings navigation, graph drag/hold playback, saving a preset from Home, remote validation, protocol parsing, host approval, and controller commands.
- `dart format`, `flutter analyze`, `flutter test` (14 tests), `flutter build web`, and `flutter build apk --debug` pass after the remote feature changes. The relay's 4 Node tests also pass.
- The latest debug APK was built; the phone is disconnected, so it has not been reinstalled.
- User confirmed real vibration works on the M2007J20CG; 100% still feels weak.
- Device dump shows the app reaches amplitude `1.0` with `Usage=TOUCH`, while the phone reports touch-feedback intensity `MEDIUM`.
- ADB changed touch-feedback intensity to HIGH; the user still reports weak output.
- Confirmed practical device/hardware strength ceiling; no supported public API path can increase output further.
- ADB install succeeds with `adb install -r`; a prior debug APK was installed and launched on the phone.
- Project restructured to a standard Flutter layout: `models`, `providers`, `services`, `utils`, `widgets`, and `pages`.
- Per-file source documentation moved from beside the code to `docs/code/`, mirroring each source path.
- Reusable app, capability, and platform text centralized in `lib/constants/`.
- UI consolidated around Home, Remote, and Settings; Home owns the local core loop, Remote owns pairing, and Settings owns capability details.
- Shared `PresetTile` added for Home; new `VibrationGraph` provides the boxed waveform strength control.
- Home graph now vibrates while touched: hold duration controls pulse time up to 5 seconds, vertical movement changes strength, and release stops playback.
- Playback now ignores stale async results through a session token, preventing quick hold/release races.
- Added a violet/mint/coral Material 3 palette with matching light and dark schemes, rounded icon badges, gradient waveform, and floating navigation.
- Bundled Manrope typography and switched UI iconography to rounded Material icons.
- Removed the standalone Presets page; the preset library remains on Home.
- Added paired remote haptics:
  - Remote is a third tab with Host and Control modes.
  - Host creates a six-digit room code and must approve every controller.
  - Controller joins by code, waits for approval, then holds a remote graph to drive the host phone.
  - Host playback status is relayed back to the controller.
  - Either phone can end the session; lifecycle hide, disconnect, expiry, and errors stop playback.
- Added `lib/config/remote_config.dart`, `lib/models/remote_models.dart`, `lib/services/remote_control_service.dart`, `lib/services/websocket_remote_control_service.dart`, `lib/providers/remote_control_controller.dart`, `lib/utils/remote_validator.dart`, and `lib/pages/remote_page.dart`.
- Added a Node.js WebSocket relay under `relay/` with six-digit rooms, host approval, role enforcement, rate limits, message-size limits, heartbeat, and expiry. It has 4 passing tests and a Dockerfile.
- Added `web_socket_channel` for the remote transport. Local haptics remain offline.

## 2. In Progress

- Reinstall the latest APK when the phone reconnects; `adb devices` is currently empty.
- Verify stop, timing, background cancellation, local graph/preset flow, and remote approval/playback on physical devices.
- Deploy the relay behind TLS so two phones can connect over the internet with `wss://`.
- UX review of the three-tab layout in Chrome.
- Prepare the persistence stage for settings and user presets.

## 3. Blockers and Exceptions

| Item | Impact | Required action |
|---|---|---|
| Weak haptic strength at app 100% | Confirmed device limitation: amplitude 255 and HIGH touch intensity remain weak | Accept and document the hardware ceiling; do not attempt root or unsafe motor overdrive |
| Non-amplitude Android device not confirmed | Unsupported-amplitude fallback cannot be fully validated | Confirm a second device or record a testing exception |
| Relay not deployed | Internet remote pairing is unavailable | Deploy `relay/` behind TLS and pass `wss://...` |
| Remote physical validation pending | Approval, live playback, and teardown are unverified on real phones | Test with the `M2007J20CG` and a second phone or browser controller |
| Physical phone disconnected | Latest APK is not installed | Reconnect and reinstall when available |
| iOS environment not validated | iOS build and Core Haptics behavior are unverified | Use the available macOS/Xcode environment later |
| `adb` not on `PATH` | Device tooling cannot call `adb` by name | Add the SDK platform-tools directory to `PATH` |
| `ANDROID_HOME` not set | Flutter works by auto-detection, but tooling is less explicit | Set it to `C:\Users\Chester\AppData\Local\Android\Sdk` |
| iOS target mismatch | The Flutter template targets iOS 15.0 while the approved plan says iOS 13.0 | Reconcile before iOS implementation |

## 4. Not Started

- Stage 8 pattern editor, post-MVP.
- Stage 9 SharedPreferences persistence.
- Stage 10 physical-device hardening.
- Stage 11 privacy review.
- Stage 12 release preparation.
- iOS implementation and validation.

## 5. Verification Commands

```powershell
flutter analyze
flutter test
flutter build web
flutter build apk --debug
flutter run -d chrome --dart-define=RELAY_URL=ws://localhost:8080/ws
flutter run -d d1ec8596
Set-Location relay
npm.cmd test
```

## 6. Next Action

Deploy the relay behind TLS and reinstall the APK when phones are available. Validate local Home playback, remote approval, remote hold/stop, and background teardown on two physical devices. Then review the three-tab UX in Chrome and proceed to the deferred persistence stage. Do not pursue motor overdrive.
