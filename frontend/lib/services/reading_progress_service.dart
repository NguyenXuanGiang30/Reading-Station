/// ReadingProgressService - Track reading progress and history
library;

import 'api_service.dart';

class ReadingProgressService {
  final ApiService _api = ApiService();
  
  /// Update reading progress for a user book
  Future<Map<String, dynamic>?> updateProgress({
    required String userBookId,
    required int currentPage,
    int? readingMinutes,
    String? note,
  }) async {
    try {
      final response = await _api.post('/user-books/$userBookId/progress', data: {
        'currentPage': currentPage,
        'readingMinutes': readingMinutes,
        'note': note,
      });
      return response.data;
    } catch (e) {
      throw Exception('Không thể cập nhật tiến độ: $e');
    }
  }
  
  /// Get reading progress history
  Future<Map<String, dynamic>> getProgressHistory({
    required String userBookId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _api.get(
        '/user-books/$userBookId/progress/history',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );
      return response.data ?? {};
    } catch (e) {
      throw Exception('Không thể tải lịch sử tiến độ: $e');
    }
  }
  
  /// Get today's reading stats
  Future<Map<String, dynamic>> getTodayStats() async {
    try {
      final response = await _api.get('/reading/today');
      return response.data ?? {};
    } catch (e) {
      // Return empty if endpoint doesn't exist
      return {};
    }
  }
  
  /// Get weekly reading stats
  Future<List<dynamic>> getWeeklyStats() async {
    try {
      final response = await _api.get('/reading/weekly');
      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }
}
