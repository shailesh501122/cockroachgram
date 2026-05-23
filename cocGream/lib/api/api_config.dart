import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Base URL of the CockroachGram API.
///
/// Override at build time:
///   flutter run --dart-define=API_BASE_URL=https://api.cockroachgram.in/api
///
/// Defaults:
/// - Android **emulator** auto-resolves to `http://10.0.2.2:8000/api`
///   (10.0.2.2 is the emulator's loopback to the host).
/// - Android **physical device** uses `http://localhost:8000/api`; on the
///   host run `adb reverse tcp:8000 tcp:8000` first.
/// - Everything else (iOS sim, web, desktop, tests) uses `http://localhost:8000/api`.
String get apiBaseUrl {
  const override = String.fromEnvironment('API_BASE_URL');
  if (override.isNotEmpty) return override;

  if (!kIsWeb && Platform.isAndroid) {
    // The Android emulator forwards 10.0.2.2 → host loopback. Physical devices
    // need adb-reverse, in which case localhost is correct too.
    const emulator = bool.fromEnvironment('ANDROID_EMULATOR');
    return emulator
        ? 'http://10.0.2.2:8000/api'
        : 'http://localhost:8000/api';
  }
  return 'http://localhost:8000/api';
}
