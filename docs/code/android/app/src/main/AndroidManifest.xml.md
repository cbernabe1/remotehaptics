# android/app/src/main/AndroidManifest.xml

## Purpose

Declares the Android application, launcher activity, Flutter embedding metadata, package-visibility queries, and required permissions.

## Current settings

- Display label: `Vibration Control`
- Launcher activity: `.MainActivity`
- Single-top launch mode
- Flutter embedding version 2
- Text-processing query for the Flutter engine
- Normal `android.permission.VIBRATE` permission for app-generated haptics

## Permissions

`android.permission.VIBRATE` is required for native playback. It is a normal permission and does not require a runtime prompt.

## Notes

The manifest must not claim system-wide vibration capability. Review the merged release manifest during the privacy review.
