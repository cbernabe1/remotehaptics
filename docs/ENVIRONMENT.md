# Development Environment Baseline

> **Status:** Stage 2 complete; Android install and native playback worked on the physical phone. The phone is currently disconnected, and paired remote mode needs a deployed relay and two phones.
> **Captured:** 2026-10-30 on the current Windows development host.
> **Source of truth:** Re-run the checks below after any toolchain change.

## 1. Host

| Item | Value |
|---|---|
| Operating system | Windows 11 or higher, 25H2, build 10.0.26200.9711 |
| Architecture | x64 |
| Project path | `C:\Users\Chester\Desktop\personalapp` |
| Repository status | Not a Git repository yet |

## 2. Installed Toolchain

| Tool | Version | Location or notes |
|---|---|---|
| Flutter | 3.47.9, stable | `C:\Users\Chester\Downloads\flutter` |
| Dart | 3.13.7 | Included with Flutter |
| DevTools | 2.60.0 | Included with Flutter |
| Java | OpenJDK 21.0.12.1 LTS, Temurin | `java` is on `PATH` |
| Android Studio | 2026.2.2.8, build AI-262.10968.63.2622.16730706 | `C:\Program Files\Android\Android Studio` |
| Android SDK | 36.0.0 | `C:\Users\Chester\AppData\Local\Android\Sdk`; platforms 35 and 36 installed |
| Android NDK | 28.2.13676358 | `C:\Users\Chester\AppData\Local\Android\Sdk\ndk\28.2.13676358` |
| Android CMake | 3.22.1 | `C:\Users\Chester\AppData\Local\Android\Sdk\cmake\3.22.1` |
| Android platform-tools / `adb` | 37.0.1 | `C:\Users\Chester\AppData\Local\Android\Sdk\platform-tools\adb.exe`; not on `PATH` |
| Android cmdline-tools | Latest | `sdkmanager.bat` installed; not on `PATH` |
| Android emulator | 37.2.13.0 | `Medium_Phone_API_37.0` available |
| Chrome | 156.0.8078.48 | Enabled as the UI preview target |
| Flutter web target | Enabled | `flutter build web` passes |
| Edge | 156.0.4314.50 | Web target only |
| Windows desktop target | Available | Not a mobile haptics target |
| Node.js | 24.20.0 | Runs `relay/server.js` |
| npm | 11.19.0 | Use `npm.cmd`; `npm.ps1` is blocked by PowerShell execution policy |
| Relay dependencies | `ws` | Installed under `relay/node_modules`; not committed |

## 3. Missing or Unhealthy Components

| Component | Status | Impact |
|---|---|---|
| "Install via USB" on the phone | Enabled and approved | No longer blocking; `adb install -r` succeeds |
| `adb` on `PATH` | Not configured | Direct `adb.exe` works, but device tooling cannot call it by name |
| `ANDROID_HOME` | Not set | Auto-detection works, but an explicit SDK path is recommended |
| `ANDROID_SDK_ROOT` | Not set | Auto-detection works, but an explicit SDK path is recommended |
| `JAVA_HOME` | Not set | Java works through `PATH`, but Gradle configuration is less explicit |
| Physical Android install | Working | Native playback and device validation can proceed |
| Visual Studio C++ workload | Missing | Windows desktop builds unavailable; not required for the mobile MVP |
| macOS / Xcode | Not available on this Windows host | iOS builds and iOS haptic validation are blocked here |
| Relay deployment | Not configured | Remote mode needs a reachable `wss://` relay; local testing can use `ws://localhost:8080/ws` |
| Relay URL | Not set | Pass `--dart-define=RELAY_URL=wss://...` for built APKs, or enter a LAN/deployed URL in Remote |

## 4. Flutter Doctor Summary

Healthy:

- Flutter stable
- Windows version
- Android toolchain: SDK 36.0.0, platform android-37.0, build-tools 36.0.0
- Android licenses accepted
- Android emulator 37.2.13.0
- Android NDK 28.2.13676358
- Chrome
- Network resources
- Android target `M2007J20CG` (Android 12, API 31) when connected; Windows, Chrome, and Edge remain available

Unhealthy or incomplete:

- `adb` is not on `PATH`.
- `ANDROID_HOME` and `ANDROID_SDK_ROOT` are not set.
- Visual Studio: not installed; not required for the mobile MVP.
- The phone is detected and accepts debug APK installs.

## 5. Flutter Configuration

`flutter config --list` shows no explicit SDK path overrides and no disabled mobile platforms. Android and iOS feature flags are available.

## 6. Commands Used for This Baseline

```powershell
flutter --version
flutter doctor -v
flutter devices
flutter config --list
java -version
adb version
node --version
npm.cmd --version
```

`adb version` failed because `adb` is not on `PATH`.

## 7. Stage 2 Installation Checklist

- [x] Install Android Studio.
- [x] Complete Android Studio first-run setup or open SDK Manager.
- [x] Install the Android SDK through Android Studio.
- [x] Install Android SDK Platform Tools.
- [x] Install Android SDK platform 37.0 and build-tools 36.0.0.
- [x] Install Android SDK Command-line Tools (latest).
- [x] Accept Android SDK licenses.
- [x] Install Android NDK 28.2.13676358.
- [ ] Set `ANDROID_HOME` to `C:\Users\Chester\AppData\Local\Android\Sdk`.
- [ ] Add `C:\Users\Chester\AppData\Local\Android\Sdk\platform-tools` to `PATH`.
- [ ] Verify `adb` is on `PATH`.
- [x] Create or configure an Android emulator for UI testing.
- [x] Enable USB debugging on the physical Android device.
- [x] Connect the device and authorize the host.
- [x] Run `flutter doctor -v` and confirm the Android toolchain is healthy.
- [x] Run `flutter devices` and confirm the physical device is listed.
- [x] Enable "Install via USB" on the phone and approve the install prompt.
- [x] Install and launch the debug APK on the Android device.
- [x] Record the Android device in `docs/DEVICE_TEST_LOG.md`.
- [ ] On macOS, install Xcode, accept the license, and verify an iOS build.
- [ ] Record the iPhone 8+ in `docs/DEVICE_TEST_LOG.md`.
- [ ] Update this document with the final working versions.

## 8. Toolchain Pinning

The MVP must record the exact Flutter, Dart, Java, Android SDK, Gradle, and Xcode versions once the environment is healthy. Do not rely on an unpinned latest toolchain for release work.

## 9. Stage 2 Exit Gate

Stage 2 is complete only when:

- `flutter doctor -v` reports a healthy Android toolchain.
- The Flutter-required Android NDK is installed and `flutter build apk --debug` succeeds.
- A sample Flutter application installs and launches on the physical Android device.
- The physical Android device is visible to Flutter.
- The iOS path is either verified on macOS or explicitly recorded as blocked.
- The device inventory is recorded.

## 10. Current Blocker

The Android toolchain is healthy: SDK 36.0.0, platform android-37.0, build-tools 36.0.0, cmdline-tools, NDK 28.2.13676358, CMake 3.22.1, and accepted licenses are detected. `flutter build web` and `flutter build apk --debug` pass, and `adb install -r` previously succeeded on the `M2007J20CG`.

Remote pairing is not production-ready until the Node relay is deployed behind TLS. The app defaults to `ws://localhost:8080/ws` on web/desktop and `ws://10.0.2.2:8080/ws` on the Android emulator. A physical phone must receive a LAN or deployed `wss://` URL through `--dart-define=RELAY_URL=...` or the Remote screen. `adb` remains available by full path but is not on `PATH`, and `ANDROID_HOME` is not set.
