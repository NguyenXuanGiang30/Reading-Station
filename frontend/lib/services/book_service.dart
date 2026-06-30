/// Book Service - API calls for book management
library;

import 'package:dio/dio.dart';
import '../models/book.dart';
import 'api_service.dart';
import '../exceptions/app_exception.dart';

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
    } on AppException {
      rethrow;
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
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Không thể tải thông tin sách: $e');
    }
  }
  
  /// Get book by ISBN (from Google Books API first, then internal)
  Future<Map<String, dynamic>?> getBookByIsbn(String isbn) async {
    // Try internal API first (which uses Google Books with API Key if configured)
    try {
      final response = await _api.get('/books/isbn/$isbn');
      if (response.data != null) {
        return {
          ...response.data,
          'totalPages': response.data['pageCount'],
          'coverUrl': response.data['coverImageUrl'],
          'found': true,
        };
      }
    } on AppException catch (e) {
      // Don't rethrow here so we can proceed to fallbacks
      print('BookService: backend ISBN lookup failed (${e.statusCode}), falling back to external API: ${e.message}');
    } catch (e) {
      // If backend returns 404, it means it's not found in DB nor Google Books (via backend)
      print('BookService: backend ISBN lookup failed, falling back to external API: $e');
    }
    
    // Fallback to direct Google Books API (public, limited quota)
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
      print('BookService: external Google Books API failed: $e');
    }

    // Fallback to Open Library API
    try {
      final openLibDio = Dio();
      final openLibResponse = await openLibDio.get(
        'https://openlibrary.org/api/books',
        queryParameters: {
          'bibkeys': 'ISBN:$isbn',
          'format': 'json',
          'jscmd': 'data'
        },
      );
      
      if (openLibResponse.data != null && openLibResponse.data['ISBN:$isbn'] != null) {
        final bookData = openLibResponse.data['ISBN:$isbn'];
        return {
          'title': bookData['title'] ?? '',
          'author': (bookData['authors'] as List?)?.map((a) => a['name']).join(', ') ?? '',
          'publisher': (bookData['publishers'] as List?)?.map((p) => p['name']).join(', ') ?? '',
          'description': bookData['notes'] ?? '',
          'coverUrl': bookData['cover']?['large'] ?? bookData['cover']?['medium'] ?? '',
          'totalPages': bookData['number_of_pages'] ?? 0,
          'isbn': isbn,
          'category': (bookData['subjects'] as List?)?.firstOrNull?['name'] ?? '',
          'found': true,
        };
      }
    } catch (e) {
      print('BookService: direct Open Library lookup failed: $e');
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
    } on AppException {
      rethrow;
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
    } on AppException {
      rethrow;
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
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Không thể cập nhật tiến độ: $e');
    }
  }
  
  /// Delete book
  Future<bool> deleteBook(String id) async {
    try {
      await _api.delete('/books/$id');
      return true;
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Không thể xóa sách: $e');
    }
  }
  
  /// Get reading statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await _api.get('/books/statistics');
      return response.data ?? {};
    } on AppException {
      rethrow;
    } catch (e) {
      return {};
    }
  }
  
  /// Get currently reading books
  Future<List<Book>> getCurrentlyReading() async {
    return getMyBooks(status: ReadingStatus.reading, size: 5);
  }
}
