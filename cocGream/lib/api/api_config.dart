/// Base URL of the CockroachGram API.
///
/// Defaults to the live production backend so a fresh `flutter run` against a
/// physical phone just works.
///
/// Override at build/run time for local development:
///
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api      # emulator
///   flutter run --dart-define=API_BASE_URL=http://localhost:8000/api     # adb-reverse
///   flutter run --dart-define=API_BASE_URL=https://api.example.com/api   # alt env
String get apiBaseUrl {
  const override = String.fromEnvironment('API_BASE_URL');
  return override.isNotEmpty
      ? override
      : 'http://155.248.250.88/api';
}
