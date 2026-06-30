/// Friend Service - API calls for social features
library;

import 'api_service.dart';
import '../exceptions/app_exception.dart';

class FriendService {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> getFriends({int page = 0, int size = 50}) async {
    try {
      final response = await _api.get('/friends', queryParameters: {
        'page': page,
        'size': size,
      });

      if (response.data != null) {
        final content = response.data['content'] as List? ?? const [];
        return content
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }
      return [];
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the tai danh sach ban be: $e');
    }
  }

  Future<Map<String, dynamic>?> getFriendProfile(String friendId) async {
    try {
      final response = await _api.get('/friends/$friendId/profile');
      return response.data as Map<String, dynamic>?;
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the tai thong tin ban be: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFriendBooks(String friendId) async {
    try {
      final response = await _api.get('/friends/$friendId/books');
      if (response.data != null) {
        return (response.data as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }
      return [];
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the tai sach cua ban be: $e');
    }
  }

  Future<bool> sendFriendRequest(String userId) async {
    try {
      await _api.post('/friends/request/$userId');
      return true;
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the gui loi moi: $e');
    }
  }

  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      await _api.put('/friends/$requestId/accept');
      return true;
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the chap nhan loi moi: $e');
    }
  }

  Future<bool> rejectFriendRequest(String requestId) async {
    try {
      await _api.delete('/friends/$requestId');
      return true;
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the tu choi loi moi: $e');
    }
  }

  Future<bool> removeFriend(String friendId) async {
    try {
      await _api.delete('/friends/$friendId');
      return true;
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the xoa ban be: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    return getFriends();
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await _api.get('/users/search', queryParameters: {
        'q': query,
      });

      if (response.data != null) {
        if (response.data is Map && response.data.containsKey('content')) {
          return (response.data['content'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        }
        if (response.data is List) {
          return (response.data as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        }
      }
      return [];
    } on AppException {
      rethrow;
    } catch (_) {
      return [];
    }
  }

  Future<bool> followUser(String userId) async {
    return sendFriendRequest(userId);
  }

  Future<bool> unfollowUser(String userId) async {
    return removeFriend(userId);
  }
}
