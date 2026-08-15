import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/user.dart';

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  Future<User> login(String usr, String pwd) async {
    final data = await _client.postMethod('zeus.api.mobile.login', {
      'usr': usr.trim(),
      'pwd': pwd,
    });
    final session = _asMap(data is Map ? data['session'] : null);
    if (session == null) {
      throw const ApiException('Login succeeded but the session payload was missing');
    }
    return User.fromSession(session);
  }

  Future<User> getSession() async {
    final data = await _client.postMethod('zeus.api.mobile.get_session');
    final session = _asMap(data);
    if (session == null) {
      throw const ApiException('Session payload was missing');
    }
    return User.fromSession(session);
  }

  /// Returns the persisted session user, or null if cookies are missing/expired.
  Future<User?> restoreSession() async {
    try {
      return await getSession();
    } on ApiException {
      await _client.clearCookies();
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _client.postMethod('logout');
    } on ApiException {
      // Still drop local cookies so the UI can return to login.
    } finally {
      await _client.clearCookies();
    }
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}
