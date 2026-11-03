import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibration_control/models/vibration_models.dart';
import 'package:vibration_control/services/android_vibration_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.example.vibration_control/haptics');
  const service = AndroidVibrationService();
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'getCapabilities' => {
              'platform': 'Android',
              'osVersion': 'Android 12 (API 31)',
              'hasActuator': true,
              'supportsAmplitude': true,
              'supportsIntensity': false,
              'supportsCustomPatterns': true,
              'supportsStop': true,
              'supportsCoreHaptics': false,
              'supportsLegacyVibration': true,
              'warnings': <String>[],
            },
            'play' => {
              'started': true,
              'effectiveMode': 'amplitude',
              'warnings': <String>[],
              'requestId': 'request-1',
              'errorCode': null,
            },
            'stop' => null,
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('maps native capabilities', () async {
    final report = await service.getCapabilities();

    expect(report.platform, 'Android');
    expect(report.osVersion, 'Android 12 (API 31)');
    expect(report.hasActuator, isTrue);
    expect(report.supportsAmplitude, isTrue);
    expect(report.warnings, isEmpty);
  });

  test('serializes play requests and maps results', () async {
    final result = await service.play(
      VibrationRequest.single(durationMs: 300, strengthPercent: 60),
    );

    expect(result.started, isTrue);
    expect(result.effectiveMode, PlaybackMode.amplitude);
    expect(result.requestId, 'request-1');
    expect(calls.single.method, 'play');

    final arguments = calls.single.arguments as Map<Object?, Object?>;
    expect(arguments['repeatCount'], 1);
    expect(arguments.containsKey('channel'), isFalse);
    final segments = arguments['segments'] as List<Object?>;
    expect(segments.single, {
      'vibrationMs': 300,
      'pauseAfterMs': 0,
      'strengthPercent': 60,
    });
  });

  test('sends stop to the native channel', () async {
    await service.stop();

    expect(calls.single.method, 'stop');
  });
}
