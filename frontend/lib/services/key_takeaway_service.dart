/// KeyTakeawayService - Book key takeaways management
library;

import 'api_service.dart';

class KeyTakeawayService {
  final ApiService _api = ApiService();
  
  /// Get all key takeaways for a user book
  Future<List<dynamic>> getKeyTakeaways(String userBookId) async {
    try {
      final response = await _api.get('/user-books/$userBookId/takeaways');
      return response.data ?? [];
    } catch (e) {
      throw Exception('Không thể tải key takeaways: $e');
    }
  }
  
  /// Create a new key takeaway
  Future<Map<String, dynamic>?> createKeyTakeaway({
    required String userBookId,
    required String content,
    int? pageNumber,
  }) async {
    try {
      final response = await _api.post('/user-books/$userBookId/takeaways', data: {
        'content': content,
        'pageNumber': pageNumber,
      });
      return response.data;
    } catch (e) {
      throw Exception('Không thể tạo takeaway: $e');
    }
  }
  
  /// Update a key takeaway
  Future<Map<String, dynamic>?> updateKeyTakeaway({
    required String takeawayId,
    required String content,
  }) async {
    try {
      final response = await _api.put('/takeaways/$takeawayId', data: {
        'content': content,
      });
      return response.data;
    } catch (e) {
      throw Exception('Không thể cập nhật takeaway: $e');
    }
  }
  
  /// Delete a key takeaway
  Future<bool> deleteKeyTakeaway(String takeawayId) async {
    try {
      await _api.delete('/takeaways/$takeawayId');
      return true;
    } catch (e) {
      throw Exception('Không thể xóa takeaway: $e');
    }
  }
  
  /// Reorder key takeaways
  Future<List<dynamic>> reorderTakeaways(List<String> takeawayIds) async {
    try {
      final response = await _api.put('/takeaways/reorder', data: {
        'takeawayIds': takeawayIds,
      });
      return response.data ?? [];
    } catch (e) {
      throw Exception('Không thể sắp xếp lại takeaways: $e');
    }
  }
  
  /// Create flashcard from takeaway
  Future<Map<String, dynamic>?> createFlashcardFromTakeaway(String takeawayId) async {
    try {
      final response = await _api.post('/takeaways/$takeawayId/flashcard');
      return response.data;
    } catch (e) {
      throw Exception('Không thể tạo flashcard: $e');
    }
  }
}
