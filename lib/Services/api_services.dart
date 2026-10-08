import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_exception.dart';

class ApiServices {
  // ---------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------
  static final ApiServices _instance = ApiServices._internal();
  factory ApiServices() => _instance;
  ApiServices._internal();

  late Dio _dio;
  bool _initialized = false;

  static const String baseUrl = 'http://127.0.0.1:3000';
  static const String _tokenKey = 'auth_token';

  String? _token;

  // ---------------------------------------------------------------
  // Init — call once from main()
  // ---------------------------------------------------------------
  Future<void> init() async {
    if (_initialized) return;

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      // Anything >= 400 becomes a DioException
      validateStatus: (status) => status != null && status < 400,
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }

    // Attach the JWT to every outgoing request
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_token == null) {
          final prefs = await SharedPreferences.getInstance();
          _token = prefs.getString(_tokenKey);
        }
        if (_token != null && _token!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
    ));

    // Restore token from disk
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);

    _initialized = true;
  }

  Dio get client => _dio;

  // ---------------------------------------------------------------
  // Token
  // ---------------------------------------------------------------
  String? get token => _token;

  Future<void> setToken(String? token, {bool persist = true}) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();

    if (token == null) {
      // Always clear both — logout must wipe disk regardless
      await prefs.remove(_tokenKey);
      return;
    }

    if (persist) {
      await prefs.setString(_tokenKey, token);
    } else {
      // Keep in memory only — remove any older token from disk
      await prefs.remove(_tokenKey);
    }
  }

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<dynamic> uploadFilePut(
      String endpoint, {
        required FormData data,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
      }) =>
      _request(() => _dio.put(
        endpoint,
        data: data,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        options: Options(contentType: 'multipart/form-data'),
      ));

  // ---------------------------------------------------------------
  // Core — unwrap { ok, data } or throw ApiException
  // ---------------------------------------------------------------
  dynamic _unwrap(Response res) {
    final body = res.data;

    if (body is Map && body['ok'] == true) {
      return body['data'];
    }

    if (body is Map) {
      final msg = body['error'] is String
          ? body['error'] as String
          : body['errors'] is List
          ? (body['errors'] as List).join('\n')
          : 'Request failed';
      throw ApiException(msg, statusCode: res.statusCode);
    }

    throw ApiException('Unexpected server response',
        statusCode: res.statusCode);
  }

  String _describe(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out. Is the API running?';
      case DioExceptionType.receiveTimeout:
        return 'Server took too long to respond.';
      case DioExceptionType.sendTimeout:
        return 'Request timed out while sending data.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'Cannot connect to server at $baseUrl';
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        if (data is Map) {
          if (data['error'] is String) return data['error'] as String;
          if (data['errors'] is List) {
            return (data['errors'] as List).join('\n');
          }
        }
        switch (e.response?.statusCode) {
          case 400: return 'Bad request.';
          case 401: return 'Unauthorized. Please log in again.';
          case 403: return 'Access forbidden.';
          case 404: return 'Not found.';
          case 405: return 'Method not allowed.';
          case 409: return 'Conflict — record is in use.';
          case 500: return 'Server error.';
          case 503: return 'Service unavailable.';
          default:  return 'Server error: ${e.response?.statusCode}';
        }
      default:
        return 'Network error. Check your connection.';
    }
  }

  /// Every method routes through here. Returns the server's `data` field,
  /// or throws ApiException on any failure.
  Future<dynamic> _request(Future<Response> Function() send) async {
    await _ensureInit();
    try {
      final res = await send();
      return _unwrap(res);
    } on DioException catch (e) {
      throw ApiException(_describe(e), statusCode: e.response?.statusCode);
    }
  }

  // ---------------------------------------------------------------
  // HTTP methods — return unwrapped `data`
  // ---------------------------------------------------------------
  Future<dynamic> get(
      String endpoint, {
        Map<String, dynamic>? queryParams,
        CancelToken? cancelToken,
      }) =>
      _request(() => _dio.get(
        endpoint,
        queryParameters: queryParams,
        cancelToken: cancelToken,
      ));

  Future<dynamic> post(
      String endpoint, {
        dynamic data,
        CancelToken? cancelToken,
      }) =>
      _request(() =>
          _dio.post(endpoint, data: data, cancelToken: cancelToken));

  Future<dynamic> put(
      String endpoint, {
        dynamic data,
        CancelToken? cancelToken,
      }) =>
      _request(() =>
          _dio.put(endpoint, data: data, cancelToken: cancelToken));

  Future<dynamic> patch(
      String endpoint, {
        dynamic data,
        CancelToken? cancelToken,
      }) =>
      _request(() =>
          _dio.patch(endpoint, data: data, cancelToken: cancelToken));

  Future<dynamic> delete(
      String endpoint, {
        dynamic data,
        CancelToken? cancelToken,
      }) =>
      _request(() =>
          _dio.delete(endpoint, data: data, cancelToken: cancelToken));

  // ---------------------------------------------------------------
  // Upload / download
  // ---------------------------------------------------------------
  Future<dynamic> uploadFile(
      String endpoint, {
        required FormData data,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
      }) =>
      _request(() => _dio.post(
        endpoint,
        data: data,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        options: Options(contentType: 'multipart/form-data'),
      ));

  Future<Response> downloadFile(
      String endpoint, {
        required String savePath,
        CancelToken? cancelToken,
        ProgressCallback? onReceiveProgress,
      }) async {
    await _ensureInit();
    try {
      return await _dio.download(
        endpoint,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw ApiException(_describe(e), statusCode: e.response?.statusCode);
    }
  }

  Future<void> _ensureInit() async {
    if (!_initialized) await init();
  }
}