/// Book Service - API calls for book management
library;

import 'package:dio/dio.dart';
import '../models/book.dart';
import 'api_service.dart';

class BookService {
  final ApiService _api = ApiService();  
  
  /// Get all books for current user
  Future<List<Book>> getMyBooks({
    ReadingStatus? status,
    String? category,
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      
      if (status != null) {
        queryParams['status'] = status.name.toUpperCase();
      }
      if (category != null) {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      final response = await _api.get('/books', queryParameters: queryParams);
      
      if (response.data != null) {
        final content = response.data['content'] as List;
        return content.map((json) => Book.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tải danh sách sách: $e');
    }
  }
  
  /// Get book by ID
  Future<Book?> getBookById(String id) async {
    try {
      final response = await _api.get('/books/$id');
      if (response.data != null) {
        return Book.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Không thể tải thông tin sách: $e');
    }
  }
  
  /// Get book by ISBN (from Google Books API first, then internal)
  Future<Map<String, dynamic>?> getBookByIsbn(String isbn) async {
    // Try Google Books API first (public, no key needed)
    try {
      final googleDio = Dio(); // Separate Dio instance for external API
      final googleResponse = await googleDio.get(
        'https://www.googleapis.com/books/v1/volumes',
        queryParameters: {'q': 'isbn:$isbn'},
      );
      
      if (googleResponse.data != null && 
          googleResponse.data['totalItems'] != null &&
          googleResponse.data['totalItems'] > 0) {
        final items = googleResponse.data['items'] as List;
        if (items.isNotEmpty) {
          final volumeInfo = items[0]['volumeInfo'];
          return {
            'title': volumeInfo['title'] ?? '',
            'author': (volumeInfo['authors'] as List?)?.join(', ') ?? '',
            'publisher': volumeInfo['publisher'] ?? '',
            'description': volumeInfo['description'] ?? '',
            'coverUrl': volumeInfo['imageLinks']?['thumbnail'] ?? '',
            'totalPages': volumeInfo['pageCount'] ?? 0,
            'isbn': isbn,
            'category': (volumeInfo['categories'] as List?)?.firstOrNull ?? '',
            'found': true,
          };
        }
      }
    } catch (e) {
      // Google Books failed, try internal API
    }
    
    // Fallback to internal API
    try {
      final response = await _api.get('/books/isbn/$isbn');
      if (response.data != null) {
        return {
          ...response.data,
          'found': true,
        };
      }
    } catch (e) {
      // Not found
    }
    
    return null;
  }
  
  /// Add a new book
  Future<Book?> addBook({
    required String title,
    required String author,
    String? isbn,
    String? publisher,
    int? totalPages,
    String? description,
    String? coverUrl,
    String? category,
    String? location,
    ReadingStatus status = ReadingStatus.wantToRead,
  }) async {
    try {
      final response = await _api.post('/books', data: {
        'title': title,
        'author': author,
        'isbn': isbn,
        'publisher': publisher,
        'totalPages': totalPages,
        'description': description,
        'coverUrl': coverUrl,
        'category': category,
        'bookLocation': location,
        'status': status.name.toUpperCase(),
      });
      
      if (response.data != null) {
        return Book.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Không thể thêm sách: $e');
    }
  }
  
  /// Update book info
  Future<Book?> updateBook(String id, {
    String? title,
    String? author,
    String? isbn,
    String? publisher,
    int? totalPages,
    String? description,
    String? coverUrl,
    String? category,
    String? location,
    ReadingStatus? status,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (author != null) data['author'] = author;
      if (isbn != null) data['isbn'] = isbn;
      if (publisher != null) data['publisher'] = publisher;
      if (totalPages != null) data['totalPages'] = totalPages;
      if (description != null) data['description'] = description;
      if (coverUrl != null) data['coverUrl'] = coverUrl;
      if (category != null) data['category'] = category;
      if (location != null) data['bookLocation'] = location;
      if (status != null) data['status'] = status.name.toUpperCase();
      
      final response = await _api.put('/books/$id', data: data);
      if (response.data != null) {
        return Book.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Không thể cập nhật sách: $e');
    }
  }
  
  /// Update reading progress
  Future<bool> updateProgress(String bookId, int currentPage) async {
    try {
      await _api.patch('/books/$bookId/progress', data: {
        'currentPage': currentPage,
      });
      return true;
    } catch (e) {
      throw Exception('Không thể cập nhật tiến độ: $e');
    }
  }
  
  /// Delete book
  Future<bool> deleteBook(String id) async {
    try {
      await _api.delete('/books/$id');
      return true;
    } catch (e) {
      throw Exception('Không thể xóa sách: $e');
    }
  }
  
  /// Get reading statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await _api.get('/books/statistics');
      return response.data ?? {};
    } catch (e) {
      return {};
    }
  }
  
  /// Get currently reading books
  Future<List<Book>> getCurrentlyReading() async {
    return getMyBooks(status: ReadingStatus.reading, size: 5);
  }
}
