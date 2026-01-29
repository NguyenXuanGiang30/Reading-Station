/// Friend Service - API calls for social features
library;

import 'api_service.dart';

class FriendService {
  final ApiService _api = ApiService();
  
  /// Get friends list
  Future<List<Map<String, dynamic>>> getFriends({
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await _api.get('/friends', queryParameters: {
        'page': page,
        'size': size,
      });
      
      if (response.data != null) {
        final content = response.data['content'] as List;
        return content.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tải danh sách bạn bè: $e');
    }
  }
  
  /// Get friend profile
  Future<Map<String, dynamic>?> getFriendProfile(String friendId) async {
    try {
      final response = await _api.get('/friends/$friendId');
      return response.data;
    } catch (e) {
      throw Exception('Không thể tải thông tin bạn bè: $e');
    }
  }
  
  /// Get activity feed
  Future<List<Map<String, dynamic>>> getActivityFeed({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _api.get('/friends/feed', queryParameters: {
        'page': page,
        'size': size,
      });
      
      if (response.data != null) {
        final content = response.data['content'] as List;
        return content.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tải hoạt động: $e');
    }
  }
  
  /// Send friend request
  Future<bool> sendFriendRequest(String userId) async {
    try {
      await _api.post('/friends/request', data: {
        'userId': userId,
      });
      return true;
    } catch (e) {
      throw Exception('Không thể gửi lời mời: $e');
    }
  }
  
  /// Accept friend request
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      await _api.post('/friends/request/$requestId/accept');
      return true;
    } catch (e) {
      throw Exception('Không thể chấp nhận lời mời: $e');
    }
  }
  
  /// Reject friend request
  Future<bool> rejectFriendRequest(String requestId) async {
    try {
      await _api.post('/friends/request/$requestId/reject');
      return true;
    } catch (e) {
      throw Exception('Không thể từ chối lời mời: $e');
    }
  }
  
  /// Remove friend
  Future<bool> removeFriend(String friendId) async {
    try {
      await _api.delete('/friends/$friendId');
      return true;
    } catch (e) {
      throw Exception('Không thể xóa bạn bè: $e');
    }
  }
  
  /// Get pending friend requests
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      final response = await _api.get('/friends/requests/pending');
      if (response.data != null) {
        return (response.data as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  
  /// Search users
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await _api.get('/users/search', queryParameters: {
        'q': query,
      });
      
      if (response.data != null) {
        return (response.data as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  
  /// Follow user
  Future<bool> followUser(String userId) async {
    try {
      await _api.post('/friends/$userId/follow');
      return true;
    } catch (e) {
      throw Exception('Không thể theo dõi: $e');
    }
  }
  
  /// Unfollow user
  Future<bool> unfollowUser(String userId) async {
    try {
      await _api.delete('/friends/$userId/follow');
      return true;
    } catch (e) {
      throw Exception('Không thể bỏ theo dõi: $e');
    }
  }
}
