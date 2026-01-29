/// ActivityService - Social activity feed and interactions
library;

import 'api_service.dart';

class ActivityService {
  final ApiService _api = ApiService();
  
  /// Get activity feed (friends' activities)
  Future<Map<String, dynamic>> getFeed({int page = 0, int size = 20}) async {
    try {
      final response = await _api.get('/activities/feed', queryParameters: {
        'page': page,
        'size': size,
      });
      return response.data ?? {};
    } catch (e) {
      throw Exception('Không thể tải feed: $e');
    }
  }
  
  /// Like an activity
  Future<bool> likeActivity(String activityId) async {
    try {
      await _api.post('/activities/$activityId/like');
      return true;
    } catch (e) {
      throw Exception('Không thể thích bài viết: $e');
    }
  }
  
  /// Unlike an activity
  Future<bool> unlikeActivity(String activityId) async {
    try {
      await _api.delete('/activities/$activityId/like');
      return true;
    } catch (e) {
      throw Exception('Không thể bỏ thích bài viết: $e');
    }
  }
  
  /// Add comment to an activity
  Future<Map<String, dynamic>?> addComment(String activityId, String content) async {
    try {
      final response = await _api.post('/activities/$activityId/comments', data: {
        'content': content,
      });
      return response.data;
    } catch (e) {
      throw Exception('Không thể thêm bình luận: $e');
    }
  }
  
  /// Get comments of an activity
  Future<List<dynamic>> getComments(String activityId) async {
    try {
      final response = await _api.get('/activities/$activityId/comments');
      return response.data ?? [];
    } catch (e) {
      throw Exception('Không thể tải bình luận: $e');
    }
  }
}
