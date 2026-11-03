# ios/Runner/Info.plist

## Purpose

Defines the iOS application metadata and scene configuration.

## Current settings

- Display name: `Vibration Control`
- Bundle name: `vibration_control`
- Bundle identifier: inherited from `PRODUCT_BUNDLE_IDENTIFIER`
- Scene-based lifecycle enabled
- Portrait and landscape support
- Minimum frame duration enabled on phone

## Dependencies

The Xcode project supplies the actual bundle identifier and version values.

## Notes

The generated deployment target is iOS 15.0. The approved plan states iOS 13.0; this must be reconciled before iOS implementation. No haptic-specific privacy usage description is required for Core Haptics.
