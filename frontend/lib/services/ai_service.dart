/// AI Service - API calls to backend AI endpoints (Ollama)
library;

import 'api_service.dart';
import '../blocs/ai/ai_chat_state.dart';
import '../exceptions/app_exception.dart';

class AiService {
  final ApiService _api = ApiService();

  /// Check if AI (Ollama) is available
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await _api.get('/ai/health');
      return response.data as Map<String, dynamic>;
    } catch (_) {
      return {'status': 'offline', 'available': false, 'model': 'unknown'};
    }
  }

  /// Chat with AI assistant (with tool calling)
  Future<Map<String, dynamic>> chat(String message,
      {List<Map<String, String>>? history}) async {
    try {
      final data = <String, dynamic>{
        'message': message,
      };
      if (history != null && history.isNotEmpty) {
        data['history'] = history;
      }

      final response = await _api.post('/ai/chat', data: data);
      final result = response.data as Map<String, dynamic>;

      // Parse actions if present
      List<ActionResult>? actions;
      if (result['actions'] != null) {
        actions = (result['actions'] as List)
            .map((a) => ActionResult.fromJson(a as Map<String, dynamic>))
            .toList();
      }

      return {
        'reply': result['reply'] as String? ?? 'Không nhận được phản hồi.',
        'actions': actions,
      };
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Loi ket noi AI: $e');
    }
  }

  /// Generate flashcards from a note using AI
  Future<List<Map<String, dynamic>>> generateFlashcards({
    int? noteId,
    int? bookId,
    int count = 5,
  }) async {
    try {
      final data = <String, dynamic>{
        'count': count,
      };
      if (noteId != null) data['noteId'] = noteId;
      if (bookId != null) data['bookId'] = bookId;

      final response = await _api.post('/ai/generate-flashcards', data: data);
      final result = response.data as Map<String, dynamic>;
      final flashcards = result['flashcards'] as List? ?? [];
      return flashcards.cast<Map<String, dynamic>>();
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Loi tao flashcard AI: $e');
    }
  }

  /// Summarize notes of a book using AI
  Future<String> summarizeNotes(int bookId) async {
    try {
      final response = await _api.post('/ai/summarize-notes', data: {
        'bookId': bookId,
      });
      final result = response.data as Map<String, dynamic>;
      return result['summary'] as String? ?? 'Khong the tom tat.';
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Loi tom tat ghi chu: $e');
    }
  }
}
