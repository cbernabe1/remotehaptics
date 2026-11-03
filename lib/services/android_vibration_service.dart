import 'package:flutter/services.dart';

import '../constants/platform_strings.dart';
import '../models/vibration_models.dart';
import 'vibration_service.dart';

class AndroidVibrationService implements VibrationService {
  const AndroidVibrationService();

  static const _channel = MethodChannel(
    'com.example.vibration_control/haptics',
  );

  @override
  Future<CapabilityReport> getCapabilities() async {
    final data =
        await _channel.invokeMapMethod<String, Object?>('getCapabilities') ??
        const <String, Object?>{};

    return CapabilityReport(
      platform: data['platform'] as String? ?? PlatformStrings.android,
      osVersion: data['osVersion'] as String? ?? PlatformStrings.unknown,
      hasActuator: data['hasActuator'] as bool? ?? false,
      supportsAmplitude: data['supportsAmplitude'] as bool? ?? false,
      supportsIntensity: data['supportsIntensity'] as bool? ?? false,
      supportsCustomPatterns: data['supportsCustomPatterns'] as bool? ?? false,
      supportsStop: data['supportsStop'] as bool? ?? false,
      supportsCoreHaptics: data['supportsCoreHaptics'] as bool? ?? false,
      supportsLegacyVibration:
          data['supportsLegacyVibration'] as bool? ?? false,
      warnings: _stringList(data['warnings']),
    );
  }

  @override
  Future<PlaybackResult> play(VibrationRequest request) async {
    final data =
        await _channel.invokeMapMethod<String, Object?>('play', {
          'requestId': request.requestId,
          'repeatCount': request.repeatCount,
          'segments': [
            for (final segment in request.segments)
              {
                'vibrationMs': segment.vibrationMs,
                'pauseAfterMs': segment.pauseAfterMs,
                'strengthPercent': segment.strengthPercent,
              },
          ],
        }) ??
        const <String, Object?>{};

    return PlaybackResult(
      started: data['started'] as bool? ?? false,
      effectiveMode: _parsePlaybackMode(data['effectiveMode'] as String?),
      warnings: _stringList(data['warnings']),
      requestId: data['requestId'] as String? ?? request.requestId,
      errorCode: data['errorCode'] as String?,
    );
  }

  @override
  Future<void> stop() async {
    await _channel.invokeMethod<void>('stop');
  }

  static List<String> _stringList(Object? value) {
    if (value is! List<Object?>) {
      return const [];
    }
    return value.whereType<String>().toList(growable: false);
  }

  static PlaybackMode _parsePlaybackMode(String? value) {
    return PlaybackMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => PlaybackMode.unsupported,
    );
  }
}
