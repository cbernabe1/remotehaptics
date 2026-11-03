import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class VibrationGraph extends StatefulWidget {
  const VibrationGraph({
    required this.value,
    required this.onChanged,
    this.onHoldStart,
    this.onHoldEnd,
    this.enabled = true,
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final VoidCallback? onHoldStart;
  final VoidCallback? onHoldEnd;
  final bool enabled;

  static const _height = 180.0;
  static const _step = 5;

  @override
  State<VibrationGraph> createState() => _VibrationGraphState();
}

class _VibrationGraphState extends State<VibrationGraph> {
  int? _activePointer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final clampedValue = widget.value.clamp(1, 100);

    return Semantics(
      slider: true,
      label: 'Vibration strength',
      value: '$clampedValue percent',
      increasedValue:
          '${(clampedValue + VibrationGraph._step).clamp(1, 100)} percent',
      decreasedValue:
          '${(clampedValue - VibrationGraph._step).clamp(1, 100)} percent',
      enabled: widget.enabled,
      onIncrease: widget.enabled && clampedValue < 100
          ? () => _adjust(clampedValue, VibrationGraph._step)
          : null,
      onDecrease: widget.enabled && clampedValue > 1
          ? () => _adjust(clampedValue, -VibrationGraph._step)
          : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;

          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: widget.enabled ? _handlePointerDown : null,
            onPointerMove: widget.enabled ? _handlePointerMove : null,
            onPointerUp: widget.enabled ? _handlePointerEnd : null,
            onPointerCancel: widget.enabled ? _handlePointerEnd : null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: widget.enabled
                  ? (details) => _update(
                      details.localPosition.dy,
                      VibrationGraph._height,
                    )
                  : null,
              child: SizedBox(
                width: width,
                height: VibrationGraph._height,
                child: CustomPaint(
                  painter: _VibrationGraphPainter(
                    value: clampedValue,
                    lineColor: colors.primary,
                    accentColor: colors.secondary,
                    backgroundColor: colors.surfaceContainerHighest,
                    gridColor: colors.outlineVariant.withValues(alpha: 0.45),
                    handleColor: colors.primary,
                    handleHaloColor: colors.primary.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_activePointer != null) {
      return;
    }
    _activePointer = event.pointer;
    _update(event.localPosition.dy, VibrationGraph._height);
    widget.onHoldStart?.call();
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }
    _update(event.localPosition.dy, VibrationGraph._height);
  }

  void _handlePointerEnd(PointerEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }
    _activePointer = null;
    widget.onHoldEnd?.call();
  }

  void _adjust(int currentValue, int delta) {
    widget.onChanged((currentValue + delta).clamp(1, 100));
  }

  void _update(double dy, double height) {
    final nextValue = (100 * (1 - dy / height)).round().clamp(1, 100);
    widget.onChanged(nextValue);
  }
}

class _VibrationGraphPainter extends CustomPainter {
  const _VibrationGraphPainter({
    required this.value,
    required this.lineColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.gridColor,
    required this.handleColor,
    required this.handleHaloColor,
  });

  final int value;
  final Color lineColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color gridColor;
  final Color handleColor;
  final Color handleHaloColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final graphShape = RRect.fromRectAndRadius(
      bounds,
      const Radius.circular(20),
    );

    canvas.drawRRect(
      graphShape,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill,
    );
    canvas.save();
    canvas.clipRRect(graphShape);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var index = 1; index < 4; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (var index = 1; index < 6; index++) {
      final x = size.width * index / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final midY = size.height / 2;
    final normalized = value / 100;
    final amplitude = size.height * 0.34 * normalized;
    final wave = Path();
    const points = 120;

    for (var index = 0; index <= points; index++) {
      final progress = index / points;
      final x = size.width * progress;
      final envelope = 0.55 + 0.45 * math.sin(math.pi * progress);
      final y = midY - math.sin(progress * math.pi * 8) * amplitude * envelope;
      if (index == 0) {
        wave.moveTo(x, y);
      } else {
        wave.lineTo(x, y);
      }
    }

    final fillPath = Path.from(wave)
      ..lineTo(size.width, midY)
      ..lineTo(0, midY)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, size.height),
          [
            lineColor.withValues(alpha: 0.2),
            accentColor.withValues(alpha: 0.05),
          ],
        )
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      wave,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(size.width, 0), [
          lineColor,
          accentColor,
        ])
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawLine(
      Offset(0, midY),
      Offset(size.width, midY),
      Paint()
        ..color = gridColor
        ..strokeWidth = 1,
    );

    final handleX = size.width - 18;
    final handleY = size.height * (1 - normalized);
    canvas.drawCircle(
      Offset(handleX, handleY),
      10,
      Paint()
        ..color = handleHaloColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(handleX, handleY),
      5,
      Paint()
        ..color = handleColor
        ..style = PaintingStyle.fill,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_VibrationGraphPainter oldDelegate) {
    return value != oldDelegate.value ||
        lineColor != oldDelegate.lineColor ||
        accentColor != oldDelegate.accentColor ||
        backgroundColor != oldDelegate.backgroundColor ||
        gridColor != oldDelegate.gridColor ||
        handleColor != oldDelegate.handleColor ||
        handleHaloColor != oldDelegate.handleHaloColor;
  }
}
