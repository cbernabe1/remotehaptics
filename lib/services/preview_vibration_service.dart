import '../constants/platform_strings.dart';
import '../models/vibration_models.dart';
import 'vibration_service.dart';

class PreviewVibrationService implements VibrationService {
  const PreviewVibrationService();

  @override
  Future<CapabilityReport> getCapabilities() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const CapabilityReport(
      platform: PlatformStrings.webPreview,
      osVersion: PlatformStrings.chrome,
      hasActuator: true,
      supportsAmplitude: true,
      supportsIntensity: false,
      supportsCustomPatterns: true,
      supportsStop: true,
      supportsCoreHaptics: false,
      supportsLegacyVibration: false,
      warnings: [
        PlatformStrings.previewOnlyWarning,
        PlatformStrings.previewFutureWarning,
      ],
    );
  }

  @override
  Future<PlaybackResult> play(VibrationRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return PlaybackResult(
      started: true,
      effectiveMode: PlaybackMode.amplitude,
      warnings: const [PlatformStrings.simulatedPlayback],
      requestId: request.requestId,
    );
  }

  @override
  Future<void> stop() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }
}
