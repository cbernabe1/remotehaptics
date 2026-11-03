class VibrationValidator {
  static const int minDurationMs = 20;
  static const int maxDurationMs = 5000;
  static const int minStrengthPercent = 1;
  static const int maxStrengthPercent = 100;
  static const int maxPresetNameLength = 40;

  static String? validateDuration(int value) {
    if (value < minDurationMs || value > maxDurationMs) {
      return 'Use a duration between $minDurationMs and $maxDurationMs ms.';
    }
    return null;
  }

  static String? validateStrength(int value) {
    if (value < minStrengthPercent || value > maxStrengthPercent) {
      return 'Use an output level between $minStrengthPercent and $maxStrengthPercent.';
    }
    return null;
  }

  static String? validatePresetName(String value) {
    final name = value.trim();
    if (name.isEmpty) {
      return 'Enter a preset name.';
    }
    if (name.length > maxPresetNameLength) {
      return 'Use $maxPresetNameLength characters or fewer.';
    }
    return null;
  }

  static int normalizeDuration(int value) {
    return value.clamp(minDurationMs, maxDurationMs);
  }

  static int normalizeStrength(int value) {
    return value.clamp(minStrengthPercent, maxStrengthPercent);
  }
}
