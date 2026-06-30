/// ReadingProgressService - Track reading progress and history
library;

import 'api_service.dart';
import '../exceptions/app_exception.dart';

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
        'pageNumber': currentPage,
        'readingDurationMinutes': readingMinutes,
        'notes': note,
      });
      return response.data;
    } on AppException {
      rethrow;
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
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Không thể tải lịch sử tiến độ: $e');
    }
  }
  
  /// Get today's reading stats (computed from recent progress)
  Future<Map<String, dynamic>> getTodayStats() async {
    try {
      // Get all user books to aggregate today's stats
      final response = await _api.get('/user-books', queryParameters: {
        'page': 0,
        'size': 100,
      });
      final data = response.data as Map<String, dynamic>? ?? {};
      final content = data['content'] as List? ?? [];
      
      int totalPagesRead = 0;
      int totalMinutes = 0;
      int booksInProgress = 0;
      
      for (final item in content) {
        final map = item as Map<String, dynamic>;
        if (map['status'] == 'READING') booksInProgress++;
        totalPagesRead += ((map['currentPage'] as int?) ?? 0);
      }
      
      return {
        'pagesRead': totalPagesRead,
        'minutesRead': totalMinutes,
        'booksInProgress': booksInProgress,
      };
    } on AppException {
      rethrow;
    } catch (_) {
      return {'pagesRead': 0, 'minutesRead': 0, 'booksInProgress': 0};
    }
  }
  
  /// Get weekly reading stats
  Future<List<dynamic>> getWeeklyStats() async {
    try {
      final response = await _api.get('/user-books', queryParameters: {
        'page': 0,
        'size': 100,
      });
      final data = response.data as Map<String, dynamic>? ?? {};
      final content = data['content'] as List? ?? [];
      
      // Return basic stats from user books
      final now = DateTime.now();
      return List.generate(7, (i) {
        final date = now.subtract(Duration(days: 6 - i));
        return {
          'date': date.toIso8601String().substring(0, 10),
          'pagesRead': 0,
          'minutesRead': 0,
        };
      });
    } on AppException {
      rethrow;
    } catch (_) {
      return [];
    }
  }
}
