/// Base Repository - Provides common API error handling and state management
library;

import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../exceptions/app_exception.dart';

/// Result wrapper for API calls - provides success/failure states with data
class ApiResult<T> {
  final T? data;
  final String? errorMessage;
  final int? statusCode;
  final bool isSuccess;
  final AppException? exception;

  ApiResult._({
    this.data,
    this.errorMessage,
    this.statusCode,
    required this.isSuccess,
    this.exception,
  });
  
  factory ApiResult.success(T data) => ApiResult._(
    data: data,
    isSuccess: true,
  );
  
  factory ApiResult.failure({
    required String message,
    int? statusCode,
    AppException? exception,
  }) => ApiResult._(
    errorMessage: message,
    statusCode: statusCode,
    isSuccess: false,
    exception: exception,
  );
  
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, int? statusCode) failure,
  }) {
    if (isSuccess && data != null) {
      return success(data as T);
    }
    return failure(errorMessage ?? 'Unknown error', statusCode);
  }
  
  R? whenOrNull<R>({
    R Function(T data)? success,
    R Function(String message, int? statusCode)? failure,
  }) {
    if (isSuccess && data != null) {
      return success?.call(data as T);
    }
    return failure?.call(errorMessage ?? 'Unknown error', statusCode);
  }
}

/// Paginated result wrapper for list endpoints
class PaginatedResult<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNext;
  final bool hasPrevious;
  
  const PaginatedResult({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNext,
    required this.hasPrevious,
  });
  
  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final content = json['content'] as List<dynamic>? ?? [];
    return PaginatedResult(
      items: content.map((e) => itemFromJson(e as Map<String, dynamic>)).toList(),
      currentPage: json['page'] ?? json['number'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalElements'] ?? json['total'] ?? 0,
      hasNext: json['last'] ?? false,
      hasPrevious: json['first'] ?? false,
    );
  }
}

/// Abstract base repository with common API operations
abstract class BaseRepository {
  final ApiService _apiService = ApiService();
  
  ApiService get api => _apiService;
  
  /// Safe API call wrapper with consistent error handling
  Future<ApiResult<T>> safeCall<T>({
    required Future<Response<T>> Function() apiCall,
    String? customErrorMessage,
  }) async {
    try {
      final response = await apiCall();
      
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        if (response.data != null) {
          return ApiResult.success(response.data as T);
        }
        // For responses with no data but successful status
        return ApiResult.failure(
          message: 'No data returned',
          statusCode: response.statusCode,
        );
      }
      
      // Handle error status codes
      final errorData = response.data as Map<String, dynamic>?;
      final message = errorData?['message'] ?? customErrorMessage ?? 'Request failed';
      
      return ApiResult.failure(
        message: message,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResult.failure(
        message: _handleDioError(e, customErrorMessage),
        statusCode: e.response?.statusCode,
        exception: AppException.fromDioError(e),
      );
    } catch (e) {
      return ApiResult.failure(
        message: customErrorMessage ?? 'An unexpected error occurred',
        exception: AppException(e.toString()),
      );
    }
  }
  
  /// Safe API call for list endpoints with pagination
  Future<ApiResult<PaginatedResult<T>>> safeCallPaginated<T>({
    required Future<Response<dynamic>> Function() apiCall,
    required T Function(Map<String, dynamic>) itemFromJson,
    String? customErrorMessage,
  }) async {
    try {
      final response = await apiCall();
      
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data != null) {
        final paginated = PaginatedResult.fromJson(
          response.data as Map<String, dynamic>,
          itemFromJson,
        );
        return ApiResult.success(paginated);
      }
      
      final errorData = response.data as Map<String, dynamic>?;
      return ApiResult.failure(
        message: errorData?['message'] ?? customErrorMessage ?? 'Failed to load data',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResult.failure(
        message: _handleDioError(e, customErrorMessage),
        statusCode: e.response?.statusCode,
        exception: AppException.fromDioError(e),
      );
    } catch (e) {
      return ApiResult.failure(
        message: customErrorMessage ?? 'An unexpected error occurred',
        exception: AppException(e.toString()),
      );
    }
  }
  
  /// Safe API call for list endpoints without pagination
  Future<ApiResult<List<T>>> safeCallList<T>({
    required Future<Response<dynamic>> Function() apiCall,
    required T Function(Map<String, dynamic>) itemFromJson,
    String? customErrorMessage,
  }) async {
    try {
      final response = await apiCall();
      
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data != null) {
        List<dynamic> dataList;
        
        // Handle both wrapped and unwrapped responses
        if (response.data is List) {
          dataList = response.data as List<dynamic>;
        } else if (response.data is Map<String, dynamic> &&
            response.data['content'] != null) {
          dataList = response.data['content'] as List<dynamic>;
        } else {
          return ApiResult.failure(
            message: 'Invalid response format',
            statusCode: response.statusCode,
          );
        }
        
        final items = dataList
            .map((e) => itemFromJson(e as Map<String, dynamic>))
            .toList();
        
        return ApiResult.success(items);
      }
      
      final errorData = response.data as Map<String, dynamic>?;
      return ApiResult.failure(
        message: errorData?['message'] ?? customErrorMessage ?? 'Failed to load data',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResult.failure(
        message: _handleDioError(e, customErrorMessage),
        statusCode: e.response?.statusCode,
        exception: AppException.fromDioError(e),
      );
    } catch (e) {
      return ApiResult.failure(
        message: customErrorMessage ?? 'An unexpected error occurred',
        exception: AppException(e.toString()),
      );
    }
  }
  
  String _handleDioError(DioException e, String? customMessage) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return customMessage ?? 'Connection timed out. Please try again.';
    }
    
    if (e.type == DioExceptionType.connectionError) {
      return customMessage ?? 'No internet connection. Please check your network.';
    }
    
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      if (data.containsKey('message')) {
        return data['message'];
      }
    }
    
    return customMessage ?? 'Something went wrong. Please try again.';
  }
}
