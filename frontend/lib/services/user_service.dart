/// UserService - User profile management
library;

import 'package:dio/dio.dart';

import 'api_service.dart';
import '../exceptions/app_exception.dart';

class UserService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _api.get('/users/me');
      return response.data as Map<String, dynamic>?;
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the tai thong tin nguoi dung: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response = await _api.get('/users/$userId');
      return response.data as Map<String, dynamic>?;
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the tai thong tin nguoi dung: $e');
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await _api.get('/users/$userId');
      return response.data as Map<String, dynamic>? ?? {};
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the tai thong tin nguoi dung: $e');
    }
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final response = await _api.get('/users/$userId');
      return response.data as Map<String, dynamic>? ?? {};
    } on AppException {
      rethrow;
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>?> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? readingGoal,
    List<String>? favoriteGenres,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (displayName != null) data['fullName'] = displayName;
      if (bio != null) data['bio'] = bio;
      if (avatarUrl != null) data['avatarUrl'] = avatarUrl;

      final response = await _api.put('/users/profile', data: data);
      return response.data as Map<String, dynamic>?;
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the cap nhat ho so: $e');
    }
  }

  Future<Map<String, dynamic>> getReadingStats() async {
    try {
      final booksResponse = await _api.get('/user-books', queryParameters: {
        'page': 0,
        'size': 100,
      });
      final notesResponse = await _api.get('/notes', queryParameters: {
        'page': 0,
        'size': 1,
      });
      final flashcardsResponse = await _api.get('/flashcards/stats');

      final books = booksResponse.data?['content'] as List? ?? const [];
      final totalBooksRead = books.where((book) => book['status'] == 'READ').length;
      final totalReadPages = books.fold<int>(0, (sum, book) {
        final map = book as Map<String, dynamic>;
        return sum + ((map['currentPage'] as int?) ?? 0);
      });

      return {
        'totalBooksRead': totalBooksRead,
        'totalReadPages': totalReadPages,
        'totalNotes': notesResponse.data?['totalElements'] ?? 0,
        'totalFlashcards': flashcardsResponse.data?['totalCards'] ?? 0,
        'currentStreak': 0,
        'totalReadingHours': 0,
        'readingDNA': const <Map<String, dynamic>>[],
      };
    } on AppException {
      rethrow;
    } catch (_) {
      return {};
    }
  }

  Future<List<dynamic>> getAchievements() async {
    return [];
  }

  Future<String?> uploadAvatar(String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imagePath),
      });

      final response = await _api.post('/upload', data: formData);
      return response.data['url'] as String?;
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the tai anh len: $e');
    }
  }

  /// Delete current user account
  Future<bool> deleteAccount() async {
    try {
      await _api.delete('/users/me');
      return true;
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Không thể xóa tài khoản: $e');
    }
  }
}
