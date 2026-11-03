# lib/widgets/app_widgets.dart

## Purpose

Reusable presentation widgets for the MVP pages.

## Widgets

- `SectionCard`: consistent titled card with optional subtitle and a rounded primary-container icon badge.
- `InfoRow`: label/value row for capability and status data.
- `PreviewNotice`: clearly marks Chrome simulation mode with a rounded tertiary notice.
- `EmptyState`: standard empty-state message with a rounded icon badge.

## Inputs and outputs

All widgets are stateless and render based on constructor arguments and the active Material theme.

## Dependencies

- `flutter/material.dart`
- `lib/constants/app_strings.dart`

## Notes

The widgets contain no business logic or platform calls. Accessibility comes from normal Flutter text and semantics; future work should add explicit semantic labels where needed.
