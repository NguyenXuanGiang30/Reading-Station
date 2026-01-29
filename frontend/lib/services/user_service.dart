/// UserService - User profile management
library;

import 'api_service.dart';

class UserService {
  final ApiService _api = ApiService();
  
  /// Get current logged in user
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _api.get('/users/me');
      return response.data;
    } catch (e) {
      throw Exception('Không thể tải thông tin người dùng: $e');
    }
  }
  
  /// Get user by ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response = await _api.get('/users/$userId');
      return response.data;
    } catch (e) {
      throw Exception('Không thể tải thông tin người dùng: $e');
    }
  }
  
  /// Get user profile by ID (alias for getUserById)
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await _api.get('/users/$userId');
      return response.data ?? {};
    } catch (e) {
      throw Exception('Không thể tải thông tin người dùng: $e');
    }
  }
  
  /// Get user stats by ID
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final response = await _api.get('/users/$userId/stats');
      return response.data ?? {};
    } catch (e) {
      return {};
    }
  }
  
  /// Update user profile
  Future<Map<String, dynamic>?> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? readingGoal,
    List<String>? favoriteGenres,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (displayName != null) data['displayName'] = displayName;
      if (bio != null) data['bio'] = bio;
      if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
      if (readingGoal != null) data['readingGoal'] = readingGoal;
      if (favoriteGenres != null) data['favoriteGenres'] = favoriteGenres;
      
      final response = await _api.put('/users/profile', data: data);
      return response.data;
    } catch (e) {
      throw Exception('Không thể cập nhật hồ sơ: $e');
    }
  }
  
  /// Get user reading stats
  Future<Map<String, dynamic>> getReadingStats() async {
    try {
      final response = await _api.get('/users/me/stats');
      return response.data ?? {};
    } catch (e) {
      return {};
    }
  }
  
  /// Get user achievements
  Future<List<dynamic>> getAchievements() async {
    try {
      final response = await _api.get('/users/me/achievements');
      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }
  
  /// Upload avatar image
  Future<String?> uploadAvatar(String imagePath) async {
    try {
      // TODO: Implement file upload with Dio FormData
      // final formData = FormData.fromMap({
      //   'file': await MultipartFile.fromFile(imagePath),
      // });
      // final response = await _api.post('/users/avatar', data: formData);
      // return response.data['avatarUrl'];
      return null;
    } catch (e) {
      throw Exception('Không thể tải ảnh lên: $e');
    }
  }
}
