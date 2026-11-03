import 'package:flutter/foundation.dart';

abstract final class RemoteConfig {
  static const _definedRelayUrl = String.fromEnvironment('RELAY_URL');

  static const maxHoldMs = 5000;
  static const approvalTimeoutMs = 60000;
  static const roomLifetimeMs = 10 * 60 * 1000;

  static String get defaultRelayUrl {
    if (_definedRelayUrl.isNotEmpty) {
      return _definedRelayUrl;
    }
    if (kIsWeb) {
      return 'ws://localhost:8080/ws';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ws://10.0.2.2:8080/ws';
    }
    return 'ws://localhost:8080/ws';
  }

  static const defaultDisplayName = 'My phone';
}
