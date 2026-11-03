abstract final class RemoteValidator {
  static const codeLength = 6;

  static const maxDisplayNameLength = 24;

  static String normalizeCode(String value) {
    return value.replaceAll(RegExp(r'\s+'), '');
  }

  static String? validateCode(String value) {
    final code = normalizeCode(value);
    if (code.length != codeLength || !RegExp(r'^\d{6}$').hasMatch(code)) {
      return 'Enter the 6-digit room code.';
    }
    return null;
  }

  static String? validateRelayUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'ws' && uri.scheme != 'wss') ||
        uri.host.isEmpty) {
      return 'Use a ws:// or wss:// relay URL.';
    }
    return null;
  }

  static String? validateDisplayName(String value) {
    final name = value.trim();
    if (name.isEmpty) {
      return 'Enter a display name.';
    }
    if (name.length > maxDisplayNameLength) {
      return 'Use $maxDisplayNameLength characters or fewer.';
    }
    if (RegExp(r'[\u0000-\u001F\u007F]').hasMatch(name)) {
      return 'Remove control characters from the name.';
    }
    return null;
  }
}
