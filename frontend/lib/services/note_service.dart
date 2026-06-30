/// Note Service - API calls for notes management
library;

import 'package:dio/dio.dart';

import '../models/note.dart';
import 'api_service.dart';
import '../exceptions/app_exception.dart';

class NoteService {
  final ApiService _api = ApiService();

  Future<List<Note>> getNotesByBook(String bookId, {int page = 0, int size = 50}) async {
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
        final content = response.data['content'] as List? ?? const [];
        return content
            .map((json) => Note.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the tai ghi chu: $e');
    }
  }

  Future<List<Note>> getAllNotes({int page = 0, int size = 50, String? search}) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };

      final response = await _api.get(
        search != null && search.isNotEmpty ? '/notes/search' : '/notes',
        queryParameters: {
          ...queryParams,
          if (search != null && search.isNotEmpty) 'q': search,
        },
      );

      if (response.data != null) {
        final content = response.data['content'] as List? ?? const [];
        return content
            .map((json) => Note.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Khong the tai ghi chu: $e');
    }
  }

  Future<Note?> getNoteById(String id) async {
    try {
      final response = await _api.get('/notes/$id');
      if (response.data != null) {
        return Note.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Khong the tai ghi chu: $e');
    }
  }

  Future<Note?> createNote({
    required String bookId,
    required String content,
    int? pageNumber,
    String? ocrImageUrl,
    List<String>? tags,
    bool createFlashcard = false,
  }) async {
    try {
      final response = await _api.post('/notes', data: {
        'bookId': bookId,
        'content': content,
        'pageNumber': pageNumber,
        'tags': (tags ?? []).join(','),
        'ocrImageUrl': ocrImageUrl,
      });

      if (response.data != null) {
        final note = Note.fromJson(response.data as Map<String, dynamic>);
        if (createFlashcard) {
          await createFlashcardFromNote(note.id);
        }
        return note;
      }
      return null;
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the tao ghi chu: $e');
    }
  }

  Future<Note?> updateNote(String id, {String? content, int? pageNumber, List<String>? tags}) async {
    try {
      final data = <String, dynamic>{};
      if (content != null) data['content'] = content;
      if (pageNumber != null) data['pageNumber'] = pageNumber;
      if (tags != null) data['tags'] = tags.join(',');

      final response = await _api.put('/notes/$id', data: data);
      if (response.data != null) {
        return Note.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the cap nhat ghi chu: $e');
    }
  }

  Future<bool> deleteNote(String id) async {
    try {
      await _api.delete('/notes/$id');
      return true;
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the xoa ghi chu: $e');
    }
  }

  Future<int> getNotesCount(String bookId) async {
    try {
      final response = await _api.get('/notes', queryParameters: {
        'bookId': bookId,
        'page': 0,
        'size': 1,
      });
      return response.data?['totalElements'] ?? 0;
    } on AppException {
      rethrow;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> createFlashcardFromNote(String noteId) async {
    try {
      await _api.post('/notes/$noteId/convert-to-flashcard');
      return true;
    } on DioException catch (e) {
      throw Exception('Khong the tao flashcard: ${e.message}');
    } catch (e) {
      throw Exception('Khong the tao flashcard: $e');
    }
  }
}
