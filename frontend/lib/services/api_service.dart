/// API Service - Dio HTTP Client with JWT Interceptor
/// Fixed version with proper token refresh handling
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../exceptions/app_exception.dart';

/// Callback type for token refresh events
typedef TokenRefreshCallback = void Function();

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  // Token refresh callbacks - notify AuthBloc when token is refreshed
  static TokenRefreshCallback? _onTokenRefreshed;
  static TokenRefreshCallback? _onTokenExpired;

  // Track if token refresh is in progress - using Completer for proper async handling
  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];

  // Track refresh token to prevent duplicate refresh attempts
  String? _currentRefreshToken;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiUrl,
        connectTimeout: Duration(milliseconds: ApiConfig.connectTimeout),
        receiveTimeout: Duration(milliseconds: ApiConfig.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (ApiConfig.enableLogging) {
      debugPrint(
        'API: initialized with baseUrl=${ApiConfig.apiUrl} '
        '(env=${ApiConfig.baseUrl})',
      );
    }

    _setupInterceptors();
  }

  /// Set callback for token refresh events
  static void setTokenRefreshCallback({
    TokenRefreshCallback? onTokenRefreshed,
    TokenRefreshCallback? onTokenExpired,
  }) {
    _onTokenRefreshed = onTokenRefreshed;
    _onTokenExpired = onTokenExpired;
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to requests
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Add debug info in dev mode
          if (ApiConfig.enableLogging) {
            options.headers['X-Debug-Request'] = 'true';
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 errors (unauthorized) - try token refresh
          if (error.response?.statusCode == 401) {
            // Don't try refresh for auth endpoints themselves
            if (error.requestOptions.path.contains('/auth/')) {
              return handler.next(error);
            }

            // Check if we should skip refresh (e.g., explicit logout)
            if (error.requestOptions.headers['X-Skip-Refresh'] == true) {
              return handler.next(error);
            }

            // If already refreshing, queue this request
            if (_isRefreshing) {
              // Use the current refresh token to ensure consistency
              final queuedRequest = _PendingRequest(
                options: error.requestOptions,
                handler: handler,
                originalError: error,
              );
              _pendingRequests.add(queuedRequest);
              return;
            }

            _isRefreshing = true;
            // Mark this specific refresh token as in progress
            _currentRefreshToken = await getRefreshToken();

            if (_currentRefreshToken == null) {
              // No refresh token available - clear tokens and notify
              await clearTokens();
              _notifyTokenExpired();
              _rejectAllPendingRequests(error);
              return handler.next(error);
            }

            try {
              // Attempt token refresh using a separate Dio instance
              // to avoid interceptors loop
              final refreshDio = Dio(
                BaseOptions(
                  baseUrl: ApiConfig.apiUrl,
                  connectTimeout: const Duration(seconds: 10),
                  receiveTimeout: const Duration(seconds: 10),
                  headers: {'Content-Type': 'application/json'},
                ),
              );

              final response = await refreshDio.post(
                '/auth/refresh',
                data: {'refreshToken': _currentRefreshToken},
              );

              if (response.statusCode == 200 && response.data != null) {
                final data = response.data as Map<String, dynamic>;
                final newToken = data['token'] ?? data['accessToken'];
                final newRefreshToken = data['refreshToken'];

                if (newToken != null) {
                  // Save new tokens
                  await saveToken(newToken);
                  if (newRefreshToken != null) {
                    await saveRefreshToken(newRefreshToken);
                  }

                  // Update the current refresh token for pending requests
                  _currentRefreshToken = newRefreshToken;

                  // Notify auth bloc of successful refresh
                  _notifyTokenRefreshed();

                  // Retry original request with new token
                  error.requestOptions.headers['Authorization'] =
                      'Bearer $newToken';
                  final retryResponse = await _dio.fetch(error.requestOptions);

                  // Retry all pending requests after successful refresh
                  await _retryAllPendingRequests(newToken);

                  return handler.resolve(retryResponse);
                }
              }

              // Refresh failed - clear tokens
              await clearTokens();
              _notifyTokenExpired();
              _rejectAllPendingRequests(error);
              return handler.next(error);
            } catch (e) {
              // Refresh exception - clear tokens
              await clearTokens();
              _notifyTokenExpired();
              _rejectAllPendingRequests(error);
              return handler.next(error);
            } finally {
              _isRefreshing = false;
              _currentRefreshToken = null;
            }
          }
          return handler.next(error);
        },
      ),
    );

    // Logging interceptor - only in non-production
    if (ApiConfig.enableLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: false, // Prevent Flutter Tools crash on Web
          error: true,
          logPrint: (obj) => debugPrint('API: $obj'),
        ),
      );
    }
  }

  void _notifyTokenRefreshed() {
    _onTokenRefreshed?.call();
  }

  void _notifyTokenExpired() {
    _onTokenExpired?.call();
  }

  Future<void> _retryAllPendingRequests(String newToken) async {
    if (_pendingRequests.isEmpty) return;

    // Create a copy and clear the list
    final requests = List<_PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();

    // Retry each pending request
    for (final request in requests) {
      try {
        request.options.headers['Authorization'] = 'Bearer $newToken';
        // Remove skip refresh flag
        request.options.headers.remove('X-Skip-Refresh');

        final response = await _dio.fetch(request.options);
        request.handler.resolve(response);
      } catch (e) {
        // If retry fails, pass the error
        request.handler.next(
          DioException(
            requestOptions: request.options,
            error: e,
            type: DioExceptionType.unknown,
          ),
        );
      }
    }
  }

  void _rejectAllPendingRequests(DioException originalError) {
    for (final request in _pendingRequests) {
      request.handler.next(originalError);
    }
    _pendingRequests.clear();
  }

  // Token Management
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // HTTP Methods with retry capability
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    int retryCount = 0,
    int maxRetries = 3,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      if (_shouldRetry(e) && retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return get<T>(
          path,
          queryParameters: queryParameters,
          options: options,
          retryCount: retryCount + 1,
          maxRetries: maxRetries,
        );
      }
      throw AppException.fromDioError(e);
    } catch (e) {
      throw AppException('Lỗi không xác định: $e');
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    } catch (e) {
      throw AppException('Lỗi không xác định: $e');
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    } catch (e) {
      throw AppException('Lỗi không xác định: $e');
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    } catch (e) {
      throw AppException('Lỗi không xác định: $e');
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    } catch (e) {
      throw AppException('Lỗi không xác định: $e');
    }
  }

  bool _shouldRetry(DioException e) {
    // Retry on connection timeout or server errors
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.response?.statusCode == 503;
  }
}

/// Helper class to track pending requests during token refresh
class _PendingRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;
  final DioException originalError;

  _PendingRequest({
    required this.options,
    required this.handler,
    required this.originalError,
  });
}
