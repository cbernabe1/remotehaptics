import 'package:uuid/uuid.dart';

enum PlaybackMode {
  amplitude,
  onOff,
  fixed,
  unsupported;

  String get label => switch (this) {
    PlaybackMode.amplitude => 'Amplitude',
    PlaybackMode.onOff => 'On/off fallback',
    PlaybackMode.fixed => 'Fixed system feedback',
    PlaybackMode.unsupported => 'Unsupported',
  };
}

class VibrationSegment {
  const VibrationSegment({
    required this.vibrationMs,
    required this.pauseAfterMs,
    required this.strengthPercent,
  });

  final int vibrationMs;
  final int pauseAfterMs;
  final int strengthPercent;
}

class VibrationRequest {
  const VibrationRequest({
    required this.requestId,
    required this.segments,
    required this.repeatCount,
  });

  factory VibrationRequest.single({
    required int durationMs,
    required int strengthPercent,
  }) {
    return VibrationRequest(
      requestId: const Uuid().v4(),
      segments: [
        VibrationSegment(
          vibrationMs: durationMs,
          pauseAfterMs: 0,
          strengthPercent: strengthPercent,
        ),
      ],
      repeatCount: 1,
    );
  }

  final String requestId;
  final List<VibrationSegment> segments;
  final int repeatCount;

  int get totalDurationMs {
    final patternMs = segments.fold<int>(
      0,
      (total, segment) => total + segment.vibrationMs + segment.pauseAfterMs,
    );
    return patternMs * repeatCount;
  }
}

class VibrationPreset {
  const VibrationPreset({
    required this.id,
    required this.name,
    required this.segments,
    required this.repeatCount,
    this.createdOnPlatform,
  });

  final String id;
  final String name;
  final List<VibrationSegment> segments;
  final int repeatCount;
  final String? createdOnPlatform;

  VibrationRequest toRequest() {
    return VibrationRequest(
      requestId: const Uuid().v4(),
      segments: segments,
      repeatCount: repeatCount,
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.defaultDurationMs,
    required this.defaultStrengthPercent,
    required this.appHapticsEnabled,
    this.selectedPresetId,
  });

  static const defaults = AppSettings(
    defaultDurationMs: 300,
    defaultStrengthPercent: 60,
    appHapticsEnabled: true,
  );

  final int defaultDurationMs;
  final int defaultStrengthPercent;
  final bool appHapticsEnabled;
  final String? selectedPresetId;

  AppSettings copyWith({
    int? defaultDurationMs,
    int? defaultStrengthPercent,
    bool? appHapticsEnabled,
    String? selectedPresetId,
  }) {
    return AppSettings(
      defaultDurationMs: defaultDurationMs ?? this.defaultDurationMs,
      defaultStrengthPercent:
          defaultStrengthPercent ?? this.defaultStrengthPercent,
      appHapticsEnabled: appHapticsEnabled ?? this.appHapticsEnabled,
      selectedPresetId: selectedPresetId ?? this.selectedPresetId,
    );
  }
}

class CapabilityReport {
  const CapabilityReport({
    required this.platform,
    required this.osVersion,
    required this.hasActuator,
    required this.supportsAmplitude,
    required this.supportsIntensity,
    required this.supportsCustomPatterns,
    required this.supportsStop,
    required this.supportsCoreHaptics,
    required this.supportsLegacyVibration,
    required this.warnings,
  });

  final String platform;
  final String osVersion;
  final bool hasActuator;
  final bool supportsAmplitude;
  final bool supportsIntensity;
  final bool supportsCustomPatterns;
  final bool supportsStop;
  final bool supportsCoreHaptics;
  final bool supportsLegacyVibration;
  final List<String> warnings;

  bool get isPreview => platform.toLowerCase().contains('preview');
}

class PlaybackResult {
  const PlaybackResult({
    required this.started,
    required this.effectiveMode,
    required this.warnings,
    required this.requestId,
    this.errorCode,
  });

  final bool started;
  final PlaybackMode effectiveMode;
  final List<String> warnings;
  final String requestId;
  final String? errorCode;
}

class PlaybackState {
  const PlaybackState({required this.isPlaying, this.lastResult, this.message});

  const PlaybackState.idle()
    : isPlaying = false,
      lastResult = null,
      message = null;

  final bool isPlaying;
  final PlaybackResult? lastResult;
  final String? message;
}

class BuiltInPresets {
  static const soft = VibrationPreset(
    id: 'builtin-soft',
    name: 'Soft',
    segments: [
      VibrationSegment(vibrationMs: 120, pauseAfterMs: 0, strengthPercent: 35),
    ],
    repeatCount: 1,
    createdOnPlatform: 'built-in',
  );

  static const normal = VibrationPreset(
    id: 'builtin-normal',
    name: 'Normal',
    segments: [
      VibrationSegment(vibrationMs: 300, pauseAfterMs: 0, strengthPercent: 60),
    ],
    repeatCount: 1,
    createdOnPlatform: 'built-in',
  );

  static const strong = VibrationPreset(
    id: 'builtin-strong',
    name: 'Strong',
    segments: [
      VibrationSegment(vibrationMs: 500, pauseAfterMs: 0, strengthPercent: 100),
    ],
    repeatCount: 1,
    createdOnPlatform: 'built-in',
  );

  static const doublePulse = VibrationPreset(
    id: 'builtin-double-pulse',
    name: 'Double pulse',
    segments: [
      VibrationSegment(vibrationMs: 120, pauseAfterMs: 80, strengthPercent: 75),
      VibrationSegment(vibrationMs: 120, pauseAfterMs: 0, strengthPercent: 75),
    ],
    repeatCount: 1,
    createdOnPlatform: 'built-in',
  );

  static const all = [soft, normal, strong, doublePulse];
}
