# lib/constants/capability_strings.dart

## Purpose

Centralizes reusable capability labels and status values used by the Settings capability report.

## Key constants

- Labels: `environment`, `actuator`, `outputControl`, `patterns`, `androidAmplitude`, `iosIntensity`, `coreHaptics`, `customPatterns`, `stop`, `legacyVibration`.
- Status values: `available`, `unavailable`, `supported`, `notReported`, `limitedUnavailable`.

## Inputs and outputs

Exposes compile-time `String` constants only. No runtime state or platform calls.

## Usage

Use these constants when rendering `InfoRow` labels and capability status values.

## Notes

Platform names and platform-specific warnings live in `platform_strings.dart`. The Compatibility page was removed; Settings now renders this report.
