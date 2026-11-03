import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibration_control/app.dart';
import 'package:vibration_control/models/remote_models.dart';
import 'package:vibration_control/models/vibration_models.dart';
import 'package:vibration_control/providers/app_state.dart';
import 'package:vibration_control/providers/remote_control_controller.dart';
import 'package:vibration_control/services/remote_control_service.dart';
import 'package:vibration_control/services/vibration_service.dart';
import 'package:vibration_control/utils/remote_validator.dart';
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

class _FakeRemoteControlService implements RemoteControlService {
  final _events = StreamController<RemoteEvent>.broadcast();
  final calls = <String>[];
  String? relayUrl;
  bool closed = false;

  @override
  Stream<RemoteEvent> get events => _events.stream;

  @override
  Future<void> connect(String relayUrl) async {
    this.relayUrl = relayUrl;
    calls.add('connect');
  }

  @override
  void createRoom(String displayName) {
    calls.add('create:$displayName');
  }

  @override
  void joinRoom({required String code, required String displayName}) {
    calls.add('join:$code:$displayName');
  }

  @override
  void decideJoin(bool approved) {
    calls.add('decision:$approved');
  }

  @override
  void sendHaptic(RemoteHapticAction action, {int? strengthPercent}) {
    calls.add('haptic:${action.name}:${strengthPercent ?? 0}');
  }

  @override
  void sendHapticStatus({
    required bool playing,
    required int strengthPercent,
    String? message,
  }) {
    calls.add('status:$playing:$strengthPercent:${message ?? ''}');
  }

  @override
  void leave() {
    calls.add('leave');
  }

  @override
  Future<void> close() async {
    closed = true;
    await _events.close();
  }

  void emit(RemoteEvent event) {
    _events.add(event);
  }
}

class _Harness {
  const _Harness({required this.vibration, required this.remote});

  final _RecordingVibrationService vibration;
  final _FakeRemoteControlService remote;
}

Future<_Harness> _pumpRemoteApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final vibration = _RecordingVibrationService();
  final remote = _FakeRemoteControlService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vibrationServiceProvider.overrideWithValue(vibration),
        remoteServiceFactoryProvider.overrideWithValue(() => remote),
      ],
      child: const VibrationControlApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Remote'));
  await tester.pumpAndSettle();
  return _Harness(vibration: vibration, remote: remote);
}

void main() {
  group('RemoteValidator', () {
    test('validates room codes, URLs, and names', () {
      expect(RemoteValidator.validateCode('123 456'), isNull);
      expect(RemoteValidator.validateCode('12345'), isNotNull);
      expect(RemoteValidator.validateCode('12a456'), isNotNull);
      expect(
        RemoteValidator.validateRelayUrl('ws://localhost:8080/ws'),
        isNull,
      );
      expect(
        RemoteValidator.validateRelayUrl('wss://relay.example/ws'),
        isNull,
      );
      expect(
        RemoteValidator.validateRelayUrl('https://relay.example'),
        isNotNull,
      );
      expect(RemoteValidator.validateDisplayName('Chester'), isNull);
      expect(RemoteValidator.validateDisplayName('   '), isNotNull);
    });
  });

  group('remote protocol parsing', () {
    test('parses session and haptic events', () {
      final session = parseRemoteEvent({
        'type': 'session_started',
        'role': 'host',
        'peerName': 'Alex',
        'code': '123456',
      });
      expect(session, isA<RemoteSessionStarted>());
      final started = session! as RemoteSessionStarted;
      expect(started.role, RemoteRole.host);
      expect(started.peerName, 'Alex');

      final command = parseRemoteEvent({
        'type': 'haptic',
        'action': 'update',
        'strength': 72,
      });
      expect(command, isA<RemoteHapticCommand>());
      expect((command! as RemoteHapticCommand).strength, 72);

      expect(parseRemoteEvent({'type': 'unknown'}), isNull);
      expect(
        parseRemoteEvent({'type': 'session_started', 'role': 'x'}),
        isNull,
      );
    });
  });

  testWidgets('host approves a controller and plays remote haptics', (
    tester,
  ) async {
    final harness = await _pumpRemoteApp(tester);

    await tester.tap(find.text('Create room code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(harness.remote.calls, contains('connect'));
    expect(harness.remote.calls, contains('create:My phone'));

    harness.remote.emit(const RemoteRoomCreated('123456'));
    await tester.pump();
    expect(find.text('123 456'), findsOneWidget);

    harness.remote.emit(const RemoteJoinRequest('Alex'));
    await tester.pump();
    expect(
      find.text('Alex wants to control app haptics on this phone.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Accept'));
    await tester.pump();
    expect(harness.remote.calls, contains('decision:true'));

    harness.remote.emit(
      const RemoteSessionStarted(
        role: RemoteRole.host,
        peerName: 'Alex',
        code: '123456',
      ),
    );
    await tester.pump();
    expect(find.text('Remote session active'), findsOneWidget);

    harness.remote.emit(
      const RemoteHapticCommand(action: RemoteHapticAction.start, strength: 75),
    );
    await tester.pumpAndSettle();
    expect(harness.vibration.requests, isNotEmpty);
    expect(harness.vibration.requests.last.segments.single.strengthPercent, 75);
    expect(find.text('Vibrating at 75%'), findsOneWidget);

    harness.remote.emit(
      const RemoteHapticCommand(action: RemoteHapticAction.stop),
    );
    await tester.pumpAndSettle();
    expect(harness.vibration.stopCount, greaterThan(0));

    await tester.tap(find.text('End remote session'));
    await tester.pumpAndSettle();
    expect(harness.remote.calls, contains('leave'));
    expect(find.text('Connect two phones.'), findsOneWidget);
  });

  testWidgets('controller joins, sends haptics, and ends the session', (
    tester,
  ) async {
    final harness = await _pumpRemoteApp(tester);

    await tester.tap(find.text('Control'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.tap(find.text('Join room'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(harness.remote.calls, contains('join:123456:My phone'));

    harness.remote.emit(
      const RemoteSessionStarted(
        role: RemoteRole.controller,
        peerName: 'Sam',
        code: '123456',
      ),
    );
    await tester.pump();
    expect(find.text('Controlling Sam'), findsOneWidget);

    final graph = find.byType(VibrationGraph);
    final gesture = await tester.startGesture(tester.getCenter(graph));
    await tester.pump(const Duration(milliseconds: 120));
    expect(
      harness.remote.calls.any((call) => call.startsWith('haptic:start:')),
      isTrue,
    );

    await gesture.moveBy(const Offset(0, -60));
    await tester.pump(const Duration(milliseconds: 120));
    expect(
      harness.remote.calls.any((call) => call.startsWith('haptic:update:')),
      isTrue,
    );

    await gesture.up();
    await tester.pump();
    expect(harness.remote.calls, contains('haptic:stop:0'));

    harness.remote.emit(
      const RemoteHapticStatus(playing: true, strength: 80, message: 'Playing'),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Sam is vibrating at 80%'), findsOneWidget);

    await tester.tap(find.text('End remote session'));
    await tester.pumpAndSettle();
    expect(harness.remote.calls, contains('leave'));
  });
}
