library;

import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  AppException(this.message, {this.code, this.statusCode});

  factory AppException.fromDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return AppException('Kết nối quá hạn. Vui lòng kiểm tra mạng và thử lại.', code: 'TIMEOUT');
    }

    if (error.type == DioExceptionType.connectionError) {
      return AppException('Lỗi mạng. Vui lòng kiểm tra kết nối internet.', code: 'NETWORK_ERROR');
    }

    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;
      
      String message = 'Đã xảy ra lỗi hệ thống.';
      String? code;

      if (data is Map<String, dynamic>) {
        message = data['message'] ?? data['error'] ?? message;
        code = data['code'];
      }

      switch (statusCode) {
        case 400:
          return AppException(message == 'Đã xảy ra lỗi hệ thống.' ? 'Yêu cầu không hợp lệ.' : message, code: code ?? 'BAD_REQUEST', statusCode: statusCode);
        case 401:
          return AppException(message == 'Đã xảy ra lỗi hệ thống.' ? 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.' : message, code: code ?? 'UNAUTHORIZED', statusCode: statusCode);
        case 403:
          return AppException(message == 'Đã xảy ra lỗi hệ thống.' ? 'Bạn không có quyền thực hiện thao tác này.' : message, code: code ?? 'FORBIDDEN', statusCode: statusCode);
        case 404:
          return AppException(message == 'Đã xảy ra lỗi hệ thống.' ? 'Không tìm thấy dữ liệu.' : message, code: code ?? 'NOT_FOUND', statusCode: statusCode);
        case 500:
        case 502:
        case 503:
          return AppException('Lỗi máy chủ. Vui lòng thử lại sau.', code: 'SERVER_ERROR', statusCode: statusCode);
        default:
          return AppException(message, code: code, statusCode: statusCode);
      }
    }

    return AppException('Không thể kết nối đến máy chủ: ${error.message}', code: 'UNKNOWN');
  }

  @override
  String toString() => message;
}
