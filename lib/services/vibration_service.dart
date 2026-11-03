import '../models/vibration_models.dart';

abstract interface class VibrationService {
  Future<CapabilityReport> getCapabilities();

  Future<PlaybackResult> play(VibrationRequest request);

  Future<void> stop();
}
