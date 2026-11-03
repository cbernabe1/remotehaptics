import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_strings.dart';
import '../constants/capability_strings.dart';
import '../providers/app_state.dart';
import '../widgets/app_widgets.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final capability = ref.watch(capabilityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionCard(
            title: 'App behavior',
            icon: Icons.tune_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Allow app haptics'),
                  subtitle: const Text(
                    'This is an app-level switch, not a system vibration setting.',
                  ),
                  value: settings.appHapticsEnabled,
                  onChanged: (value) {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setHapticsEnabled(value);
                  },
                ),
                Text(
                  'Duration and output level are adjusted on the Home page.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          capability.when(
            data: (report) {
              return Column(
                children: [
                  if (report.isPreview) const PreviewNotice(),
                  SectionCard(
                    title: AppStrings.currentCapabilityReport,
                    subtitle: 'Runtime values reported by the active service',
                    icon: Icons.verified_rounded,
                    child: Column(
                      children: [
                        InfoRow(
                          label: CapabilityStrings.environment,
                          value: '${report.platform} - ${report.osVersion}',
                        ),
                        InfoRow(
                          label: CapabilityStrings.actuator,
                          value: report.hasActuator
                              ? CapabilityStrings.available
                              : CapabilityStrings.unavailable,
                        ),
                        InfoRow(
                          label: CapabilityStrings.androidAmplitude,
                          value: report.supportsAmplitude
                              ? CapabilityStrings.supported
                              : CapabilityStrings.notReported,
                        ),
                        InfoRow(
                          label: CapabilityStrings.iosIntensity,
                          value: report.supportsIntensity
                              ? CapabilityStrings.supported
                              : CapabilityStrings.notReported,
                        ),
                        InfoRow(
                          label: CapabilityStrings.coreHaptics,
                          value: report.supportsCoreHaptics
                              ? CapabilityStrings.supported
                              : CapabilityStrings.notReported,
                        ),
                        InfoRow(
                          label: CapabilityStrings.customPatterns,
                          value: report.supportsCustomPatterns
                              ? CapabilityStrings.supported
                              : CapabilityStrings.unavailable,
                        ),
                        InfoRow(
                          label: CapabilityStrings.stop,
                          value: report.supportsStop
                              ? CapabilityStrings.supported
                              : CapabilityStrings.unavailable,
                        ),
                        InfoRow(
                          label: CapabilityStrings.legacyVibration,
                          value: report.supportsLegacyVibration
                              ? CapabilityStrings.available
                              : CapabilityStrings.notReported,
                        ),
                        if (report.warnings.isNotEmpty) ...[
                          const Divider(height: 24),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              AppStrings.warnings,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final warning in report.warnings)
                            _LimitRow(icon: Icons.info_rounded, text: warning),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const SectionCard(
              title: AppStrings.checkingCapabilities,
              icon: Icons.sensors_rounded,
              child: LinearProgressIndicator(),
            ),
            error: (error, stackTrace) => SectionCard(
              title: AppStrings.capabilityCheckFailed,
              icon: Icons.warning_amber_rounded,
              child: Text('$error'),
            ),
          ),
          const SectionCard(
            title: 'What this app cannot change',
            icon: Icons.do_not_disturb_on_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LimitRow(
                  icon: Icons.volume_off_rounded,
                  text: AppStrings.systemWideVibration,
                ),
                _LimitRow(
                  icon: Icons.notifications_off_rounded,
                  text: AppStrings.callNotificationVibration,
                ),
                _LimitRow(
                  icon: Icons.apps_rounded,
                  text: AppStrings.otherAppHaptics,
                ),
                _LimitRow(
                  icon: Icons.memory_rounded,
                  text: AppStrings.hardwareOverdrive,
                ),
              ],
            ),
          ),
          const SectionCard(
            title: 'Why results vary',
            icon: Icons.tune_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LimitRow(
                  icon: Icons.phone_android_rounded,
                  text: 'OEMs may scale or suppress Android amplitude.',
                ),
                _LimitRow(
                  icon: Icons.phone_iphone_rounded,
                  text: 'iOS may suppress haptics based on system settings.',
                ),
                _LimitRow(
                  icon: Icons.hearing_rounded,
                  text: 'Output levels are not linear measures of perceived strength.',
                ),
                _LimitRow(
                  icon: Icons.computer_rounded,
                  text: 'Emulators and browsers cannot reproduce real haptic hardware.',
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Local data',
            subtitle: 'Data stays on this device',
            icon: Icons.storage_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reset default values and remove all saved presets. This cannot be undone.',
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _confirmReset(context, ref),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text(AppStrings.resetLocalData),
                ),
              ],
            ),
          ),
          const SectionCard(
            title: 'About',
            icon: Icons.info_rounded,
            child: Text(
              'Vibration Control is an in-app haptics laboratory. It cannot change system-wide vibration, calls, notifications, or other apps.',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset local data?'),
          content: const Text(
            'Default values will be restored and every saved preset will be removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(AppStrings.reset),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    ref.read(settingsControllerProvider.notifier).reset();
    ref.read(presetControllerProvider.notifier).clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Local data reset.')));
  }
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
