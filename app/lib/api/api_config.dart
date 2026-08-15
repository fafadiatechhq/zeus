/// Backend connection settings for the Zeus Method API.
///
/// Override at build/run time:
/// ```
/// flutter run --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=API_SITE_NAME=localhost
/// ```
///
/// Android (emulator or device) cannot use `localhost` for the host machine
/// unless the port is forwarded:
/// ```
/// adb reverse tcp:8000 tcp:8000
/// ```
class ApiConfig {
  ApiConfig._();

  static const _definedBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _definedSiteName = String.fromEnvironment('API_SITE_NAME');

  static String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) {
      return _definedBaseUrl;
    }
    return 'http://localhost:8000';
  }

  static String get siteName {
    if (_definedSiteName.isNotEmpty) {
      return _definedSiteName;
    }
    return 'localhost';
  }
}
