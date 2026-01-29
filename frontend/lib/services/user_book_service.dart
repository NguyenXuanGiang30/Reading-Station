/// UserBookService - User's book library management  
library;

import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/book.dart';

class UserBookService {
  final ApiService _api = ApiService();
  
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
      return response.data ?? {};
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
      return response.data;
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
      return response.data;
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
      if (rating != null) data['rating'] = rating;
      if (review != null) data['review'] = review;
      
      final response = await _api.put('/user-books/$userBookId', data: data);
      return response.data;
    } catch (e) {
      throw Exception('Không thể cập nhật sách: $e');
    }
  }
  
  /// Delete a user book
  Future<bool> deleteUserBook(String userBookId) async {
    try {
      await _api.delete('/user-books/$userBookId');
      return true;
    } catch (e) {
      throw Exception('Không thể xóa sách: $e');
    }
  }
  
  /// Get friends who read the same book
  Future<List<dynamic>> getFriendsWhoReadBook(String userBookId) async {
    try {
      final response = await _api.get('/user-books/$userBookId/friends');
      return response.data ?? [];
    } catch (e) {
      throw Exception('Không thể tải danh sách bạn bè: $e');
    }
  }
  
  /// Get user book stats (notes count, flashcards count, etc.)
  Future<Map<String, dynamic>> getUserBookStats(String userBookId) async {
    try {
      final response = await _api.get('/user-books/$userBookId/stats');
      return response.data ?? {};
    } catch (e) {
      throw Exception('Không thể tải thống kê: $e');
    }
  }
}
