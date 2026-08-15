import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'api_config.dart';
import 'api_exception.dart';

/// Shared Dio client for Frappe Method API calls.
///
/// Persists the `sid` session cookie and copies `csrf_token` onto mutating
/// requests. Unwraps Frappe's `{ "message": ... }` envelope.
class ApiClient {
  ApiClient._(this._dio, this._cookieJar);

  static ApiClient? _instance;

  final Dio _dio;
  final CookieJar _cookieJar;

  static Future<ApiClient> create() async {
    if (_instance != null) {
      return _instance!;
    }

    final cookieJar = await _openCookieJar();
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Frappe-Site-Name': ApiConfig.siteName,
        },
        validateStatus: (status) => status != null && status < 400,
      ),
    );
    dio.interceptors.add(CookieManager(cookieJar));
    dio.interceptors.add(_CsrfInterceptor(cookieJar));

    _instance = ApiClient._(dio, cookieJar);
    return _instance!;
  }

  Future<void> clearCookies() async {
    await _cookieJar.deleteAll();
  }

  /// POST `/api/method/<method>` and return the unwrapped `message` payload.
  Future<dynamic> postMethod(String method, [Map<String, dynamic>? params]) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/method/$method',
        data: params ?? <String, dynamic>{},
      );
      return _unwrap(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static dynamic _unwrap(dynamic data) {
    if (data is Map && data.containsKey('message')) {
      return data['message'];
    }
    return data;
  }

  static Future<CookieJar> _openCookieJar() async {
    try {
      final dir = await getApplicationSupportDirectory();
      return PersistCookieJar(storage: FileStorage('${dir.path}/cookies'));
    } catch (_) {
      return CookieJar();
    }
  }
}

class _CsrfInterceptor extends Interceptor {
  _CsrfInterceptor(this._cookieJar);

  final CookieJar _cookieJar;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    await _attachCsrf(options);
    handler.next(options);
  }

  Future<void> _attachCsrf(RequestOptions options) async {
    if (options.method.toUpperCase() == 'GET') {
      return;
    }
    try {
      final cookies = await _cookieJar.loadForRequest(options.uri);
      for (final cookie in cookies) {
        if (cookie.name == 'csrf_token' && cookie.value.isNotEmpty) {
          options.headers['X-Frappe-CSRF-Token'] = cookie.value;
          return;
        }
      }
    } catch (_) {
      // Cookie jar may be empty before the first login.
    }
  }
}
