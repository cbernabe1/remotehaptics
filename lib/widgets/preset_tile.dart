import 'package:flutter/material.dart';

import '../models/vibration_models.dart';

class PresetTile extends StatelessWidget {
  const PresetTile({
    required this.preset,
    required this.onPlay,
    this.onDelete,
    super.key,
  });

  final VibrationPreset preset;
  final VoidCallback onPlay;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = preset.segments.fold<int>(
      0,
      (total, segment) => total + segment.vibrationMs + segment.pauseAfterMs,
    );
    final strength = preset.segments.first.strengthPercent;
    final segmentCount = preset.segments.length;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          segmentCount > 1
              ? Icons.multiline_chart_rounded
              : Icons.graphic_eq_rounded,
          color: theme.colorScheme.onSecondaryContainer,
          size: 22,
        ),
      ),
      title: Text(preset.name),
      subtitle: Text(
        '$duration ms · $segmentCount segment${segmentCount == 1 ? '' : 's'} · $strength%',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onPlay,
            tooltip: 'Preview ${preset.name}',
            icon: const Icon(Icons.play_arrow_rounded),
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              tooltip: 'Delete ${preset.name}',
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
    );
  }
}
