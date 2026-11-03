# lib/providers/app_state.dart

## Purpose

Contains the Riverpod providers and controllers for navigation, capabilities, settings, presets, and playback.

## Providers

- `selectedTabProvider`: active bottom-navigation index.
- `vibrationServiceProvider`: selects the native Android service on Android and the preview service on web or other platforms.
- `capabilityProvider`: asynchronous capability report.
- `settingsControllerProvider`: in-memory app settings.
- `presetControllerProvider`: in-memory user presets.
- `playbackControllerProvider`: playback state and actions.

## Key behavior

- Playback is blocked when app haptics are disabled.
- One playback timer is kept; a new request cancels the prior timer.
- Each play/stop increments a session token so stale async results cannot overwrite newer state.
- The controller catches service errors and exposes user-facing messages.
- The timer resets the UI after the requested effect duration.

## Dependencies

- `flutter_riverpod`
- `flutter/foundation.dart`
- `lib/models/vibration_models.dart`
- `lib/services/vibration_service.dart`
- Android and preview service implementations

## Notes

Settings and presets are not persisted yet; that is a later stage. Native haptics are implemented for Android only. The preview service must not ship as the production implementation.
