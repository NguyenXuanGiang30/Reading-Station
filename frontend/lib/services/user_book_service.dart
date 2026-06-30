/// UserBookService - User's book library management  
library;

import 'package:dio/dio.dart';
import 'api_service.dart';
import '../exceptions/app_exception.dart';
import '../models/book.dart';

class UserBookService {
  final ApiService _api = ApiService();

  Map<String, dynamic> _normalizeUserBook(Map<String, dynamic> raw) {
    final book = Map<String, dynamic>.from(
      (raw['book'] as Map?)?.cast<String, dynamic>() ?? raw,
    );
    final totalPages = raw['totalPages'] ?? book['totalPages'] ?? book['pageCount'];
    book['coverUrl'] = book['coverUrl'] ?? book['coverImageUrl'];
    book['totalPages'] = totalPages ?? book['totalPages'] ?? 0;

    return {
      ...raw,
      'book': book,
      'coverUrl': book['coverUrl'],
      'startDate': raw['startedAt'] ?? raw['startDate'],
      'finishDate': raw['completedAt'] ?? raw['finishDate'],
      'lastReadDate':
          raw['updatedAt'] ?? raw['completedAt'] ?? raw['startedAt'] ?? raw['lastReadDate'],
      'totalPages': totalPages ?? 0,
      'ownerId': raw['ownerId'],
      'ownerName': raw['ownerName'],
      'ownerAvatarUrl': raw['ownerAvatarUrl'],
    };
  }
  
  /// Get user's books with optional filtering
  Future<Map<String, dynamic>> getUserBooks({
    ReadingStatus? status,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (status != null) {
        queryParams['status'] = status.value;
      }
      
      final response = await _api.get('/user-books', queryParameters: queryParams);
      final data = response.data as Map<String, dynamic>? ?? {};
      final content = data['content'];
      if (content is List) {
        data['content'] = content
            .map((item) => _normalizeUserBook(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return data;
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
         final data = e.response!.data as Map;
         if (data.containsKey('message')) {
            throw Exception(data['message']);
         }
      }
      throw Exception('Không thể tải danh sách sách: ${e.message}');
    } catch (e) {
      throw Exception('Không thể tải danh sách sách: $e');
    }
  }

  /// Get a specific user book by ID
  Future<Map<String, dynamic>?> getUserBookById(String userBookId) async {
    try {
      final response = await _api.get('/user-books/$userBookId');
      final data = response.data as Map<String, dynamic>?;
      return data == null ? null : _normalizeUserBook(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
         final data = e.response!.data as Map;
         if (data.containsKey('message')) {
            throw Exception(data['message']);
         }
      }
      throw Exception('Không thể tải thông tin sách: ${e.message}');
    } catch (e) {
      throw Exception('Không thể tải thông tin sách: $e');
    }
  }
  
  /// Add a new book to user's library
  Future<Map<String, dynamic>?> addUserBook({
    String? bookId,
    String? isbn,
    required String title,
    required String author,
    String? coverUrl,
    int? totalPages,
    String? description,
    String? category,
    String? publisher,
    int? publishYear,
    String? location,
    ReadingStatus status = ReadingStatus.wantToRead,
  }) async {
    try {
      final response = await _api.post('/user-books', data: {
        'bookId': bookId,
        'isbn': isbn,
        'title': title,
        'author': author,
        'coverUrl': coverUrl,
        'totalPages': totalPages,
        'description': description,
        'category': category,
        'publisher': publisher,
        'publishYear': publishYear,
        'location': location,
        'status': status.value,
      });
      final data = response.data as Map<String, dynamic>?;
      return data == null ? null : _normalizeUserBook(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
         final data = e.response!.data as Map;
         if (data.containsKey('message')) {
            throw Exception(data['message']);
         }
      }
      throw Exception('Không thể thêm sách: ${e.message}');
    } catch (e) {
      throw Exception('Không thể thêm sách: $e');
    }
  }

  /// Update a user book
  Future<Map<String, dynamic>?> updateUserBook({
    required String userBookId,
    String? title,
    String? author,
    String? coverUrl,
    int? totalPages,
    String? description,
    String? category,
    String? location,
    ReadingStatus? status,
    double? rating,
    String? review,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (author != null) data['author'] = author;
      if (coverUrl != null) data['coverUrl'] = coverUrl;
      if (totalPages != null) data['totalPages'] = totalPages;
      if (description != null) data['description'] = description;
      if (category != null) data['category'] = category;
      if (location != null) data['location'] = location;
      if (status != null) data['status'] = status.value;
      if (rating != null) data['rating'] = rating.round();
      if (review != null) data['review'] = review;
      
      final response = await _api.put('/user-books/$userBookId', data: data);
      final responseData = response.data as Map<String, dynamic>?;
      return responseData == null ? null : _normalizeUserBook(responseData);
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Không thể cập nhật sách: $e');
    }
  }
  
  /// Delete a user book
  Future<bool> deleteUserBook(String userBookId) async {
    try {
      await _api.delete('/user-books/$userBookId');
      return true;
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Không thể xóa sách: $e');
    }
  }
  
  /// Get friends who read the same book
  Future<List<dynamic>> getFriendsWhoReadBook(String userBookId) async {
    try {
      final response = await _api.get('/user-books/$userBookId/friends');
      final data = response.data as List? ?? const [];
      return data.map((item) {
        final normalized = _normalizeUserBook(Map<String, dynamic>.from(item as Map));
        final book = Map<String, dynamic>.from(
          (normalized['book'] as Map?)?.cast<String, dynamic>() ?? {},
        );
        return {
          ...normalized,
          'id': normalized['ownerId'] ?? normalized['id'],
          'fullName': normalized['ownerName'] ?? 'Ban doc',
          'avatarUrl': normalized['ownerAvatarUrl'],
          'title': book['title'],
          'author': book['author'],
          'coverUrl': book['coverUrl'],
          'bookId': book['id'],
        };
      }).toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Không thể tải danh sách bạn bè: $e');
    }
  }
  
  /// Get user book stats (notes count, flashcards count, etc.)
  Future<Map<String, dynamic>> getUserBookStats(String userBookId) async {
    try {
      final response = await _api.get('/user-books/$userBookId/stats');
      return response.data ?? {};
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Không thể tải thống kê: $e');
    }
  }
}
