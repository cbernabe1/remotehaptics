import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_strings.dart';
import '../models/remote_models.dart';
import '../models/vibration_models.dart';
import '../providers/app_state.dart';
import '../providers/remote_control_controller.dart';
import '../utils/vibration_validator.dart';
import '../widgets/app_widgets.dart';
import '../widgets/preset_tile.dart';
import '../widgets/vibration_graph.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const _durationOptions = [100, 300, 500, 1000];

  final Stopwatch _holdStopwatch = Stopwatch();
  Timer? _holdRestartTimer;
  Timer? _holdCapTimer;
  bool _graphHolding = false;
  int? _holdPreviewStrength;
  int? _pendingHoldStrength;

  @override
  void dispose() {
    _holdRestartTimer?.cancel();
    _holdCapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final capability = ref.watch(capabilityProvider);
    final capabilityReport = capability.asData?.value;
    final playback = ref.watch(playbackControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final userPresets = ref.watch(presetControllerProvider);
    final remote = ref.watch(remoteControllerProvider);
    final canPlay = capabilityReport?.hasActuator ?? false;
    final supportsOutput =
        (capabilityReport?.supportsAmplitude ?? false) ||
        (capabilityReport?.supportsIntensity ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.graphic_eq_rounded,
                size: 18,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            const Text(AppStrings.appName),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: _graphHolding
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                'HAPTIC LAB',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Shape the pulse.',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adjust the strength, feel the change, and keep the effects that feel right.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          if (capabilityReport?.isPreview ?? false) const PreviewNotice(),
          if (remote.isActive) ...[
            _RemoteSessionNotice(
              remote: remote,
              onOpen: () => ref.read(selectedTabProvider.notifier).select(1),
            ),
            const SizedBox(height: 16),
          ],
          SectionCard(
            title: 'Strength',
            subtitle: 'Press and hold to vibrate; slide to change strength',
            icon: Icons.graphic_eq_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${settings.defaultStrengthPercent}%',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'requested output',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                VibrationGraph(
                  value: settings.defaultStrengthPercent,
                  enabled: supportsOutput,
                  onChanged: _handleGraphStrengthChanged,
                  onHoldStart: canPlay ? _startGraphHold : null,
                  onHoldEnd: canPlay ? _endGraphHold : null,
                ),
                const SizedBox(height: 12),
                Text(
                  supportsOutput
                      ? _graphHolding
                            ? 'Vibrating while you hold. Release to stop.'
                            : 'Touch and hold the graph. Vibration lasts as long as you hold, up to 5 seconds.'
                      : capability.isLoading
                      ? 'Checking output-level support.'
                      : 'This environment does not report amplitude or intensity control.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Pulse length', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'Used by Play test and saved presets.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final duration in _durationOptions)
                      ChoiceChip(
                        label: Text(_formatDuration(duration)),
                        selected: settings.defaultDurationMs == duration,
                        onSelected: (_) {
                          ref
                              .read(settingsControllerProvider.notifier)
                              .setDefaultDuration(duration);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: canPlay
                          ? () {
                              final controller = ref.read(
                                playbackControllerProvider.notifier,
                              );
                              if (playback.isPlaying) {
                                controller.stop();
                                return;
                              }
                              _previewCurrent(ref);
                            }
                          : null,
                      icon: Icon(
                        playback.isPlaying
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(
                        playback.isPlaying
                            ? AppStrings.stop
                            : AppStrings.playTest,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _savePreset(context, ref, settings),
                      icon: const Icon(Icons.bookmark_add_rounded),
                      label: const Text(AppStrings.saveAsPreset),
                    ),
                  ],
                ),
                if (capability.isLoading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                if (capability.hasError) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${AppStrings.capabilityCheckFailed}. Preview is disabled.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                if (playback.message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    playback.message!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
                if (playback.lastResult != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Effective mode: ${playback.lastResult!.effectiveMode.label}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SectionCard(
            title: 'Preset library',
            subtitle: 'Tap play to feel an effect',
            icon: Icons.auto_awesome_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final preset in BuiltInPresets.all)
                  PresetTile(
                    preset: preset,
                    onPlay: () => _playPreset(context, ref, preset),
                  ),
                if (userPresets.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text('Saved', style: theme.textTheme.titleSmall),
                  for (final preset in userPresets)
                    PresetTile(
                      preset: preset,
                      onPlay: () => _playPreset(context, ref, preset),
                      onDelete: () => _deletePreset(context, ref, preset),
                    ),
                ] else ...[
                  const Divider(height: 24),
                  Text(
                    'Save a custom effect from the strength card to see it here.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleGraphStrengthChanged(int value) {
    ref.read(settingsControllerProvider.notifier).setDefaultStrength(value);
    if (!_graphHolding) {
      return;
    }

    _pendingHoldStrength = value;
    _holdRestartTimer?.cancel();
    _holdRestartTimer = Timer(const Duration(milliseconds: 90), () {
      if (!mounted || !_graphHolding) {
        return;
      }
      final nextStrength = _pendingHoldStrength;
      if (nextStrength == null || nextStrength == _holdPreviewStrength) {
        return;
      }
      _holdPreviewStrength = nextStrength;
      _playHoldPulse(nextStrength);
    });
  }

  void _startGraphHold() {
    if (_graphHolding) {
      return;
    }

    final settings = ref.read(settingsControllerProvider);
    if (!settings.appHapticsEnabled) {
      ref
          .read(playbackControllerProvider.notifier)
          .play(
            VibrationRequest.single(
              durationMs: VibrationValidator.maxDurationMs,
              strengthPercent: settings.defaultStrengthPercent,
            ),
          );
      return;
    }

    _graphHolding = true;
    _holdPreviewStrength = settings.defaultStrengthPercent;
    _holdStopwatch
      ..reset()
      ..start();
    _playHoldPulse(settings.defaultStrengthPercent);
    _holdCapTimer?.cancel();
    _holdCapTimer = Timer(
      const Duration(milliseconds: VibrationValidator.maxDurationMs),
      _endGraphHold,
    );
    setState(() {});
  }

  void _endGraphHold() {
    _holdRestartTimer?.cancel();
    _holdCapTimer?.cancel();
    if (!_graphHolding) {
      return;
    }

    _graphHolding = false;
    _holdStopwatch.stop();
    ref.read(playbackControllerProvider.notifier).stop();
    if (mounted) {
      setState(() {});
    }
  }

  void _playHoldPulse(int strengthPercent) {
    ref
        .read(playbackControllerProvider.notifier)
        .play(
          VibrationRequest.single(
            durationMs: VibrationValidator.maxDurationMs,
            strengthPercent: strengthPercent,
          ),
        );
  }

  void _previewCurrent(WidgetRef ref) {
    final settings = ref.read(settingsControllerProvider);
    ref
        .read(playbackControllerProvider.notifier)
        .play(
          VibrationRequest.single(
            durationMs: settings.defaultDurationMs,
            strengthPercent: settings.defaultStrengthPercent,
          ),
        );
  }

  void _playPreset(
    BuildContext context,
    WidgetRef ref,
    VibrationPreset preset,
  ) {
    ref.read(playbackControllerProvider.notifier).play(preset.toRequest());
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Previewing "${preset.name}".')));
  }

  Future<void> _deletePreset(
    BuildContext context,
    WidgetRef ref,
    VibrationPreset preset,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete preset?'),
          content: Text('Remove "${preset.name}" from your presets?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(AppStrings.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    ref.read(presetControllerProvider.notifier).remove(preset.id);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Deleted "${preset.name}".')));
  }

  Future<void> _savePreset(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    var inputName = '';
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Save preset'),
          content: TextField(
            autofocus: true,
            maxLength: VibrationValidator.maxPresetNameLength,
            decoration: const InputDecoration(
              labelText: 'Preset name',
              hintText: 'My favorite pulse',
            ),
            textInputAction: TextInputAction.done,
            onChanged: (value) => inputName = value,
            onSubmitted: (value) => Navigator.pop(dialogContext, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, inputName),
              child: const Text(AppStrings.save),
            ),
          ],
        );
      },
    );

    if (name == null || !context.mounted) {
      return;
    }

    final error = VibrationValidator.validatePresetName(name);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final preset = VibrationPreset(
      id: const Uuid().v4(),
      name: name.trim(),
      segments: [
        VibrationSegment(
          vibrationMs: settings.defaultDurationMs,
          pauseAfterMs: 0,
          strengthPercent: settings.defaultStrengthPercent,
        ),
      ],
      repeatCount: 1,
      createdOnPlatform: 'user',
    );
    ref.read(presetControllerProvider.notifier).add(preset);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Saved "${preset.name}".')));
  }

  String _formatDuration(int durationMs) {
    if (durationMs >= 1000) {
      final seconds = durationMs / 1000;
      return '${seconds.toStringAsFixed(seconds % 1 == 0 ? 0 : 1)} s';
    }
    return '$durationMs ms';
  }
}

class _RemoteSessionNotice extends StatelessWidget {
  const _RemoteSessionNotice({required this.remote, required this.onOpen});

  final RemoteState remote;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_tethering_rounded,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Remote session active with ${remote.peerName ?? 'the other phone'}.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onOpen, child: const Text('Open')),
        ],
      ),
    );
  }
}
