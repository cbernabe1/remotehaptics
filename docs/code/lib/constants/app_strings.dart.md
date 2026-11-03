# lib/constants/app_strings.dart

## Purpose

Centralizes reusable app-level UI text so labels, page titles, actions, and shared notices are not duplicated across widgets.

## Key constants

- `appName`: product name used by the Material app and page headers.
- Navigation/page labels: `home`, `settings`.
- Shared actions: `playTest`, `stop`, `saveAsPreset`, `save`, `cancel`, `delete`, `reset`, `resetLocalData`.
- Status and section headings: `capabilityCheckFailed`, `checkingCapabilities`, `currentCapabilityReport`, `warnings`.
- Scope labels: `systemWideVibration`, `callNotificationVibration`, `otherAppHaptics`, `hardwareOverdrive`.
- Shared presentation text: `previewNotice`.

## Inputs and outputs

Exposes compile-time `String` constants. It has no runtime inputs, side effects, or dependencies.

## Usage

Import this file in pages and widgets when the same text is needed in more than one place. One-off explanatory copy can stay local to its page.

## Notes

User-facing strings that vary by platform belong in `platform_strings.dart`; capability labels and statuses belong in `capability_strings.dart`. Only strings used by the current Home, Remote, and Settings flows are kept here.
