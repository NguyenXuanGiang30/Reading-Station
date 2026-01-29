/// Note Service - API calls for notes management
library;

import '../models/note.dart';
import 'api_service.dart';

class NoteService {
  final ApiService _api = ApiService();
  
  /// Get all notes for a book
  Future<List<Note>> getNotesByBook(String bookId, {
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await _api.get(
        '/notes',
        queryParameters: {
          'bookId': bookId,
          'page': page,
          'size': size,
        },
      );
      
      if (response.data != null) {
        final content = response.data['content'] as List;
        return content.map((json) => Note.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tải ghi chú: $e');
    }
  }
  
  /// Get all notes for current user
  Future<List<Note>> getAllNotes({
    int page = 0,
    int size = 50,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      final response = await _api.get('/notes', queryParameters: queryParams);
      
      if (response.data != null) {
        final content = response.data['content'] as List;
        return content.map((json) => Note.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tải ghi chú: $e');
    }
  }
  
  /// Get note by ID
  Future<Note?> getNoteById(String id) async {
    try {
      final response = await _api.get('/notes/$id');
      if (response.data != null) {
        return Note.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Không thể tải ghi chú: $e');
    }
  }
  
  /// Create a new note
  Future<Note?> createNote({
    required String bookId,
    required String content,
    int? pageNumber,
    List<String>? tags,
    bool createFlashcard = false,
  }) async {
    try {
      final response = await _api.post('/notes', data: {
        'bookId': bookId,
        'content': content,
        'pageNumber': pageNumber,
        'tags': tags ?? [],
        'createFlashcard': createFlashcard,
      });
      
      if (response.data != null) {
        return Note.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Không thể tạo ghi chú: $e');
    }
  }
  
  /// Update note
  Future<Note?> updateNote(String id, {
    String? content,
    int? pageNumber,
    List<String>? tags,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (content != null) data['content'] = content;
      if (pageNumber != null) data['pageNumber'] = pageNumber;
      if (tags != null) data['tags'] = tags;
      
      final response = await _api.put('/notes/$id', data: data);
      if (response.data != null) {
        return Note.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Không thể cập nhật ghi chú: $e');
    }
  }
  
  /// Delete note
  Future<bool> deleteNote(String id) async {
    try {
      await _api.delete('/notes/$id');
      return true;
    } catch (e) {
      throw Exception('Không thể xóa ghi chú: $e');
    }
  }
  
  /// Get notes count for a book
  Future<int> getNotesCount(String bookId) async {
    try {
      final response = await _api.get('/notes/count', queryParameters: {
        'bookId': bookId,
      });
      return response.data?['count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }
  
  /// Create flashcard from note
  Future<bool> createFlashcardFromNote(String noteId) async {
    try {
      await _api.post('/notes/$noteId/flashcard');
      return true;
    } catch (e) {
      throw Exception('Không thể tạo flashcard: $e');
    }
  }
}
