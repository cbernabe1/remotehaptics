# android/app/build.gradle.kts

## Purpose

Configures the Android application module for the Flutter app.

## Current settings

- Namespace and application ID: `com.example.vibration_control`
- Compile SDK: Flutter default
- Android NDK: Flutter default (`28.2.13676358`)
- Minimum SDK: 26
- Target SDK: Flutter default
- Java and Kotlin target: JVM 17
- Release signing: debug keys for local builds

## Dependencies

Flutter Gradle plugin and Android application plugin.

## Non-obvious behavior

The NDK version is inherited from Flutter and is currently missing on this machine, so Android APK builds fail during Gradle configuration. The placeholder application ID must be replaced before release signing or store submission.
