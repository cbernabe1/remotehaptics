import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibration_control/app.dart';
import 'package:vibration_control/models/vibration_models.dart';
import 'package:vibration_control/providers/app_state.dart';
import 'package:vibration_control/services/preview_vibration_service.dart';
import 'package:vibration_control/services/vibration_service.dart';
import 'package:vibration_control/utils/vibration_validator.dart';
import 'package:vibration_control/widgets/vibration_graph.dart';

class _RecordingVibrationService implements VibrationService {
  final requests = <VibrationRequest>[];
  int stopCount = 0;

  @override
  Future<CapabilityReport> getCapabilities() async {
    return const CapabilityReport(
      platform: 'Test',
      osVersion: 'Test',
      hasActuator: true,
      supportsAmplitude: true,
      supportsIntensity: false,
      supportsCustomPatterns: true,
      supportsStop: true,
      supportsCoreHaptics: false,
      supportsLegacyVibration: false,
      warnings: [],
    );
  }

  @override
  Future<PlaybackResult> play(VibrationRequest request) async {
    requests.add(request);
    return PlaybackResult(
      started: true,
      effectiveMode: PlaybackMode.amplitude,
      warnings: const [],
      requestId: request.requestId,
    );
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }
}

Future<void> _pumpApp(
  WidgetTester tester, {
  VibrationService service = const PreviewVibrationService(),
}) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [vibrationServiceProvider.overrideWithValue(service)],
      child: const VibrationControlApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('VibrationValidator', () {
    test('accepts valid values', () {
      expect(VibrationValidator.validateDuration(300), isNull);
      expect(VibrationValidator.validateStrength(60), isNull);
      expect(VibrationValidator.validatePresetName('Morning pulse'), isNull);
    });

    test('rejects invalid values', () {
      expect(VibrationValidator.validateDuration(10), isNotNull);
      expect(VibrationValidator.validateStrength(0), isNotNull);
      expect(VibrationValidator.validatePresetName('   '), isNotNull);
    });

    test('normalizes values to the supported range', () {
      expect(VibrationValidator.normalizeDuration(1), 20);
      expect(VibrationValidator.normalizeDuration(9000), 5000);
      expect(VibrationValidator.normalizeStrength(0), 1);
      expect(VibrationValidator.normalizeStrength(200), 100);
    });
  });

  testWidgets('navigates between Home, Remote, and Settings', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Shape the pulse.'), findsOneWidget);
    expect(find.text('Preset library'), findsOneWidget);
    expect(find.text('Presets'), findsNothing);
    expect(find.text('Device status'), findsNothing);
    expect(find.text('Test and adjust'), findsNothing);
    expect(find.text('Compatibility'), findsNothing);

    await tester.tap(find.text('Remote'));
    await tester.pumpAndSettle();
    expect(find.text('Connect two phones.'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('App behavior'), findsOneWidget);
    expect(find.text('Current capability report'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Shape the pulse.'), findsOneWidget);
  });

  testWidgets('vibration graph changes strength on drag', (tester) async {
    var value = 50;
    var holdStarted = false;
    var holdEnded = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: StatefulBuilder(
              builder: (context, setState) {
                return VibrationGraph(
                  value: value,
                  onChanged: (nextValue) {
                    setState(() {
                      value = nextValue;
                    });
                  },
                  onHoldStart: () {
                    holdStarted = true;
                  },
                  onHoldEnd: () {
                    holdEnded = true;
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(VibrationGraph), const Offset(0, -60));
    await tester.pumpAndSettle();

    expect(value, greaterThan(50));
    expect(holdStarted, isTrue);
    expect(holdEnded, isTrue);
  });

  testWidgets('holding the graph starts and stops playback', (tester) async {
    final service = _RecordingVibrationService();
    await _pumpApp(tester, service: service);
    final graph = find.byType(VibrationGraph);

    final gesture = await tester.startGesture(tester.getCenter(graph));
    await tester.pump(const Duration(milliseconds: 200));

    expect(service.requests, isNotEmpty);
    expect(
      service.requests.first.segments.single.vibrationMs,
      VibrationValidator.maxDurationMs,
    );
    expect(
      find.text('Vibrating while you hold. Release to stop.'),
      findsOneWidget,
    );

    await gesture.moveBy(const Offset(0, -60));
    await tester.pump(const Duration(milliseconds: 150));
    expect(service.requests.length, greaterThan(1));
    expect(
      service.requests.last.segments.single.strengthPercent,
      greaterThan(service.requests.first.segments.single.strengthPercent),
    );

    await gesture.up();
    await tester.pump();

    expect(service.stopCount, 1);
    expect(
      find.text('Vibrating while you hold. Release to stop.'),
      findsNothing,
    );
  });

  testWidgets('saves a preset from Home', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Save as preset'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'My pulse');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('My pulse'), findsOneWidget);
  });
}
