# ios/Runner.xcodeproj/project.pbxproj

## Purpose

Xcode project configuration for the iOS runner and test targets.

## Current changes

- Runner bundle identifier: `com.example.vibration_control`
- RunnerTests bundle identifier: `com.example.vibration_control.RunnerTests`
- Deployment target: iOS 15.0

## Dependencies

- Xcode
- Flutter iOS build tooling
- CocoaPods or Swift Package Manager support from the Flutter template

## Notes

The bundle identifier is still a placeholder. iOS build and haptic validation require macOS and a physical iPhone; they have not been performed on the current Windows host. The deployment-target mismatch with the approved iOS 13 minimum must be resolved before iOS work.
