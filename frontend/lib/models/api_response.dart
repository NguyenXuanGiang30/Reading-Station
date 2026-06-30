/// API Response Wrapper - Standardized API response format
/// Ensures consistent response structure across all endpoints
library;

import 'package:dio/dio.dart';

/// API Response Wrapper - Standardized API response format
/// Wraps all API responses in a consistent structure
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
  final String? errorCode;
  final DateTime? timestamp;
  
  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.errorCode,
    this.timestamp,
  });
  
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      data: fromJsonT != null && json['data'] != null
          ? fromJsonT(json['data'] as Map<String, dynamic>)
          : null,
      message: json['message'],
      statusCode: json['statusCode'],
      errorCode: json['errorCode'],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])
          : null,
    );
  }
  
  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message ?? 'Thành công',
      statusCode: 200,
      timestamp: DateTime.now(),
    );
  }
  
  factory ApiResponse.error(String message, {int statusCode = 400, String? errorCode}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
      errorCode: errorCode,
      timestamp: DateTime.now(),
    );
  }
}

/// Page Response for paginated endpoints
class PageResponse<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;
  
  const PageResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
  });
  
  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final contentList = json['content'] as List<dynamic>? ?? [];
    return PageResponse(
      content: contentList
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      page: json['page'] ?? json['number'] ?? 0,
      size: json['size'] ?? json['pageSize'] ?? 20,
      totalElements: (json['totalElements'] ?? json['total'] ?? 0).toInt(),
      totalPages: json['totalPages'] ?? 1,
      first: json['first'] ?? true,
      last: json['last'] ?? true,
    );
  }
}

/// Extension to handle API response in services
extension ApiResponseExtension<T> on ApiResponse<T> {
  R when<R>({
    required R Function(T data) success,
    required R Function(String message) failure,
  }) {
    if (this.success && data != null) {
      return success(data as T);
    }
    return failure(message ?? 'Unknown error');
  }
}

/// Error codes enum for consistent error handling
enum ApiErrorCode {
  // Auth errors (AUTH_*)
  AUTH_INVALID_CREDENTIALS('AUTH_INVALID_CREDENTIALS', 'Tài khoản hoặc mật khẩu không đúng'),
  AUTH_TOKEN_EXPIRED('AUTH_TOKEN_EXPIRED', 'Phiên đăng nhập đã hết hạn'),
  AUTH_TOKEN_INVALID('AUTH_TOKEN_INVALID', 'Token không hợp lệ'),
  AUTH_REFRESH_TOKEN_EXPIRED('AUTH_REFRESH_TOKEN_EXPIRED', 'Refresh token đã hết hạn'),
  AUTH_USER_NOT_FOUND('AUTH_USER_NOT_FOUND', 'Người dùng không tồn tại'),
  AUTH_USER_DISABLED('AUTH_USER_DISABLED', 'Tài khoản đã bị vô hiệu hóa'),
  AUTH_EMAIL_EXISTS('AUTH_EMAIL_EXISTS', 'Email đã được sử dụng'),
  AUTH_WEAK_PASSWORD('AUTH_WEAK_PASSWORD', 'Mật khẩu không đủ mạnh'),
  
  // Validation errors (VALIDATION_*)
  VALIDATION_REQUIRED('VALIDATION_REQUIRED', 'Trường bắt buộc'),
  VALIDATION_INVALID_FORMAT('VALIDATION_INVALID_FORMAT', 'Định dạng không hợp lệ'),
  VALIDATION_TOO_SHORT('VALIDATION_TOO_SHORT', 'Giá trị quá ngắn'),
  VALIDATION_TOO_LONG('VALIDATION_TOO_LONG', 'Giá trị quá dài'),
  
  // Resource errors (RESOURCE_*)
  RESOURCE_NOT_FOUND('RESOURCE_NOT_FOUND', 'Không tìm thấy tài nguyên'),
  RESOURCE_ALREADY_EXISTS('RESOURCE_ALREADY_EXISTS', 'Tài nguyên đã tồn tại'),
  RESOURCE_DELETED('RESOURCE_DELETED', 'Tài nguyên đã bị xóa'),
  
  // Permission errors (PERMISSION_*)
  PERMISSION_DENIED('PERMISSION_DENIED', 'Không có quyền truy cập'),
  PERMISSION_FORBIDDEN('PERMISSION_FORBIDDEN', 'Bị cấm truy cập'),
  
  // Server errors (SERVER_*)
  SERVER_ERROR('SERVER_ERROR', 'Lỗi máy chủ nội bộ'),
  SERVER_UNAVAILABLE('SERVER_UNAVAILABLE', 'Dịch vụ không khả dụng'),
  SERVER_MAINTENANCE('SERVER_MAINTENANCE', 'Hệ thống đang bảo trì'),
  
  // Network errors (NETWORK_*)
  NETWORK_ERROR('NETWORK_ERROR', 'Lỗi mạng'),
  NETWORK_TIMEOUT('NETWORK_TIMEOUT', 'Kết nối quá thời gian'),
  
  // Unknown
  UNKNOWN('UNKNOWN', 'Lỗi không xác định');
  
  final String code;
  final String defaultMessage;
  
  const ApiErrorCode(this.code, this.defaultMessage);
  
  static ApiErrorCode fromCode(String code) {
    return ApiErrorCode.values.firstWhere(
      (e) => e.code == code,
      orElse: () => ApiErrorCode.UNKNOWN,
    );
  }
}

/// Extension to convert DioException to user-friendly message
extension DioExceptionExtension on DioException {
  String get userFriendlyMessage {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Kết nối quá thời gian. Vui lòng kiểm tra mạng và thử lại.';
      case DioExceptionType.connectionError:
        return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.';
      case DioExceptionType.cancel:
        return 'Yêu cầu đã bị hủy.';
      case DioExceptionType.badResponse:
        return _handleBadResponse();
      case DioExceptionType.unknown:
      default:
        return message ?? 'Đã xảy ra lỗi không mong muốn.';
    }
  }
  
  String _handleBadResponse() {
    if (response == null) return 'Phản hồi không hợp lệ từ máy chủ.';
    
    final statusCode = response?.statusCode;
    final data = response?.data;
    
    if (data is Map<String, dynamic> && data.containsKey('message')) {
      return data['message'];
    }
    
    switch (statusCode) {
      case 400:
        return 'Yêu cầu không hợp lệ.';
      case 401:
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      case 403:
        return 'Bạn không có quyền thực hiện thao tác này.';
      case 404:
        return 'Không tìm thấy tài nguyên.';
      case 429:
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      case 500:
      case 502:
      case 503:
        return 'Lỗi máy chủ. Vui lòng thử lại sau.';
      default:
        return 'Đã xảy ra lỗi. Mã lỗi: $statusCode';
    }
  }
}
