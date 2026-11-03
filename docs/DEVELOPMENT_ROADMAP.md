# Development Roadmap

> **Status:** Approved, 2026-10-30.
> **Source:** `VIBRATION_CONTROL_PLAN.md`, Section 12 and Section 19.
> **Current position:** Stage 1 is complete. Stage 2 is complete on Android: the phone accepts ADB installs and native playback works. Stage 3 is complete for web and Android debug builds. Stage 4 is implemented for Chrome preview. Stages 5-7 are implemented; playback is confirmed on the phone, but perceived strength remains weak at maximum output and is under diagnostic testing.

## 1. Delivery Strategy

- Android-first, iOS after Android validation.
- MVP first; full pattern editor deferred.
- One small coherent feature per stage.
- Each stage has a definition of done and an exit gate.
- No stage begins until the previous exit gate is met.
- Emulator output is never accepted as proof of haptic strength.

## 2. Effort Summary

| Stage | Estimate |
|---|---|
| 1. Feasibility and requirements | 1-2 days |
| 2. Environment | 0.5-1.5 days Android; +0.5-1 day iOS |
| 3. Project initialization | 0.5 day |
| 4. UI and navigation | 2-3 days |
| 5. Capability detection | 2-4 days |
| 6. Basic vibration | 1-2 days |
| 7. Intensity adjustment | 2-3 days |
| 8. Custom patterns, post-MVP | 4-6 days |
| 9. Local persistence | 1-2 days |
| 10. Testing and reliability | 3-5 days |
| 11. Security and privacy review | 0.5-1 day |
| 12. Release preparation | 2-4 days Android; +2-3 days iOS |
| 13. Future enhancements | Not estimated |

MVP estimate: 15-29 development days, with a realistic plan of 20-35 days.

Android-only MVP without iOS validation: roughly 10-20 days.

Full roadmap including the pattern editor and both platforms: roughly 24-40 days.

## 3. Stage Plan

### Stage 1 - Product feasibility and requirements

**Status:** Complete.

**Objective:** Freeze scope, verify platform restrictions, and produce the requirements baseline.

**Deliverables:**

- `docs/PROJECT_REQUIREMENTS.md`
- `docs/PLATFORM_LIMITATIONS.md`
- `docs/TECHNICAL_ARCHITECTURE.md`
- `docs/DEVELOPMENT_ROADMAP.md`
- `docs/DECISIONS.md`

**Exit gate:** Scope accepted, decisions recorded, planning documents approved.

### Stage 2 - Development environment

**Status:** Tooling complete; physical-device install authorization pending.

**Objective:** Prepare a reliable build and test environment.

**Required tasks:**

- Install Flutter stable and Dart.
- Install Android Studio and Android SDK.
- Install Android platform tools, including `adb`.
- Install JDK compatible with the Android Gradle Plugin.
- Accept Android SDK licenses.
- Create or configure an Android emulator for UI work.
- Enable USB debugging on the physical Android device.
- Verify `flutter doctor -v` and `flutter devices`.
- Pin the working toolchain versions in `docs/ENVIRONMENT.md`.
- Record device inventory in `docs/DEVICE_TEST_LOG.md`.
- On macOS, install Xcode and verify an iOS build.

**Current exception:** The Android toolchain is healthy, the phone is connected, and ADB installs work. iOS cannot be built on the Windows host.

**Exit gate:** Toolchain reports healthy, a sample app installs and launches on Android, and the iOS path is either working or explicitly blocked.

### Stage 3 - Flutter project initialization

**Status:** Web baseline and Android debug APK build complete; iOS target still needs alignment.

**Objective:** Create a clean baseline with the approved identity and dependencies.

**Tasks:**

- Set the final package and bundle identifier.
- Set Android `minSdk` to 26.
- Set iOS deployment target to 13.0.
- Add only approved dependencies.
- Configure `flutter_lints`.
- Create the folder skeleton.
- Initialize Git.
- Add a smoke test.
- Run analyzer and tests.

**Exit gate:** Clean build and test on the primary platform; no feature code beyond scaffolding.

### Stage 4 - UI and navigation

**Status:** Implemented; consolidated to three pages and awaiting UX review.

**Objective:** Build the MVP pages against fake haptics and remote services.

**Screens:**

- Home: hold-to-vibrate graph, duration chips, preset library, save preset, remote-session banner.
- Remote: host/control pairing, host approval, live remote graph, session controls.
- Settings: app behavior, capability report, limitations, reset, about.

**Exit gate:** All MVP pages are reachable, accessible, and usable without real haptics.

### Stage 5 - Native capability detection

**Status:** Implemented; physical-device validation pending.

**Objective:** Implement the MethodChannel capability report.

**Exit gate:** No false-positive capability is observed on test devices.

### Stage 6 - Basic vibration

**Status:** Implemented; native playback confirmed, stop/timing validation pending.

**Objective:** Implement one-shot playback, stop, validation, error mapping, and lifecycle handling.

**Exit gate:** Core play and stop are reliable on at least one physical device.

### Stage 7 - Intensity adjustment

**Status:** Implemented; amplitude mapping confirmed at maximum. Normal touch output is weak on the test phone, confirming a device/hardware ceiling. Unsupported-amplitude behavior still needs validation.

**Objective:** Add the graph-style 1-100 output-level control and native mapping.

**Exit gate:** Supported and unsupported behavior is explicit and verified; no misleading percentage claim remains.

### Stage 7A - Paired remote haptics

**Status:** Implemented; relay and UI tests pass. Physical two-phone validation and production relay deployment are pending.

**Objective:** Let one phone adjust app-generated haptics on another phone after explicit host approval.

**Delivered:**

- Six-digit room codes with a Node.js WebSocket relay.
- Host approval/decline and a visible active-session state.
- Live strength and hold control from a controller phone.
- Session teardown on stop, leave, disconnect, expiry, or app backgrounding.
- No message or identity persistence in the relay.

**Exit gate:** Two physical phones use the same `wss://` relay, the host approves, remote haptics are responsive, and either phone can stop the session immediately.

### Stage 8 - Custom patterns (post-MVP)

**Status:** Deferred.

**Objective:** Add user-authored multi-segment patterns after the MVP is stable.

**Exit gate:** MVP+ scope is explicitly approved.

### Stage 9 - Local persistence

**Status:** Pending.

**Objective:** Save settings and presets with a versioned JSON envelope.

**Exit gate:** Data survives restart, invalid data does not crash the app, and no silent data wipe occurs.

### Stage 10 - Testing and reliability

**Status:** Pending.

**Objective:** Harden the MVP across lifecycle, errors, and device variability.

**Exit gate:** Automated suite passes; no P0 or P1 defects; device matrix is signed off.

### Stage 11 - Security and privacy review

**Status:** Pending.

**Exit gate:** Only necessary permissions; local offline operation verified; relay uses WSS, host approval, rate limits, and no persisted messages, secrets, or PII.

### Stage 12 - Release preparation

**Status:** Pending.

**Exit gate:** Signed release candidate installs on clean devices and metadata truthfully states app-only scope.

### Stage 13 - Future enhancements

**Status:** Backlog.

**Exit gate:** Next release scope is approved and re-checked for platform feasibility.

## 4. Stage Dependencies

```text
Stage 1 -> Stage 2 -> Stage 3 -> Stage 4 -> Stage 5 -> Stage 6 -> Stage 7
                                                                  |
                                                                  +-> Stage 7A
                                                                  |
                                                                  +-> Stage 9 -> Stage 10
                                                                                  |
                                                                                  v
                                                                         Stage 11 -> Stage 12
```

Stage 8 is post-MVP and does not block the MVP path.

## 5. Immediate Next Actions

1. Deploy `relay/` behind TLS and record the `wss://` URL.
2. Reinstall the latest APK when the phone reconnects.
3. Validate local playback, remote approval, remote hold/stop, and background teardown on two physical phones.
4. Review the three-tab UI in Chrome.
5. Complete Stage 9 persistence.
6. Confirm the final package and bundle identifier before release work.
7. Add iOS native haptics on a macOS host.

## 6. Change Control

- Scope changes require an update to `docs/PROJECT_REQUIREMENTS.md` and `docs/DECISIONS.md`.
- Architecture changes require an update to `docs/TECHNICAL_ARCHITECTURE.md`.
- New dependencies require an ADR entry in `docs/DECISIONS.md`.
- Stage status changes require an update to `docs/PROGRESS.md`.
