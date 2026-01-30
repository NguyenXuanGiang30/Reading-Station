/// Flashcard Service - API calls for flashcard management with SM-2 algorithm
library;

import '../models/flashcard.dart';
import 'api_service.dart';

class FlashcardService {
  final ApiService _api = ApiService();
  
  /// Get all flashcard decks
  Future<List<FlashcardDeck>> getDecks() async {
    try {
      final response = await _api.get('/flashcards/decks');
      
      if (response.data != null) {
        final list = response.data as List;
        return list.map((json) => FlashcardDeck.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tải bộ flashcard: $e');
    }
  }
  
  /// Get deck by ID
  Future<FlashcardDeck?> getDeckById(String id) async {
    try {
      final response = await _api.get('/flashcards/decks/$id');
      if (response.data != null) {
        return FlashcardDeck.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Không thể tải thông tin bộ flashcard: $e');
    }
  }
  
  /// Get flashcards due for review
  Future<List<Flashcard>> getDueCards({String? deckId, int limit = 20}) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (deckId != null) {
        queryParams['deckId'] = deckId;
      }
      
      final response = await _api.get(
        '/flashcards/due',
        queryParameters: queryParams,
      );
      
      if (response.data != null) {
        final list = response.data as List;
        return list.map((json) => Flashcard.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tải flashcard cần ôn: $e');
    }
  }
  
  /// Get all flashcards in a deck
  Future<List<Flashcard>> getCardsByDeck(String deckId) async {
    try {
      final response = await _api.get('/flashcards/decks/$deckId/cards');
      
      if (response.data != null) {
        final list = response.data as List;
        return list.map((json) => Flashcard.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tải flashcard: $e');
    }
  }
  
  /// Create a new flashcard
  Future<Flashcard?> createCard({
    required String deckId,
    required String front,
    required String back,
    String? noteId,
  }) async {
    try {
      final response = await _api.post('/flashcards', data: {
        'deckId': deckId,
        'front': front,
        'back': back,
        'noteId': noteId,
      });
      
      if (response.data != null) {
        return Flashcard.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Không thể tạo flashcard: $e');
    }
  }

  /// Create a flashcard from a note
  Future<Flashcard?> createCardFromNote(String noteId) async {
    try {
      final response = await _api.post('/flashcards/from-note/$noteId');
      
      if (response.data != null) {
        return Flashcard.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Không thể tạo flashcard từ ghi chú: $e');
    }
  }
  
  /// Update flashcard
  Future<Flashcard?> updateCard(String id, {
    String? front,
    String? back,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (front != null) data['front'] = front;
      if (back != null) data['back'] = back;
      
      final response = await _api.put('/flashcards/$id', data: data);
      if (response.data != null) {
        return Flashcard.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Không thể cập nhật flashcard: $e');
    }
  }
  
  /// Delete flashcard
  Future<bool> deleteCard(String id) async {
    try {
      await _api.delete('/flashcards/$id');
      return true;
    } catch (e) {
      throw Exception('Không thể xóa flashcard: $e');
    }
  }
  
  /// Submit review result (SM-2 algorithm)
  /// quality: 0 (Again), 1 (Hard), 2 (Good), 3 (Easy)
  Future<Flashcard?> submitReview(String cardId, int quality) async {
    try {
      final response = await _api.post('/flashcards/$cardId/review', data: {
        'quality': quality,
      });
      
      if (response.data != null) {
        return Flashcard.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Không thể lưu kết quả: $e');
    }
  }
  
  /// Get review statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await _api.get('/flashcards/statistics');
      return response.data ?? {};
    } catch (e) {
      return {};
    }
  }
  
  /// Get today's review summary
  Future<Map<String, dynamic>> getTodaySummary() async {
    try {
      final response = await _api.get('/flashcards/today');
      return response.data ?? {
        'reviewed': 0,
        'due': 0,
        'new': 0,
      };
    } catch (e) {
      return {'reviewed': 0, 'due': 0, 'new': 0};
    }
  }
  
  /// Create a new deck
  Future<FlashcardDeck?> createDeck({
    required String name,
    required String bookId,
    String? description,
  }) async {
    try {
      final response = await _api.post('/flashcards/decks', data: {
        'name': name,
        'bookId': bookId,
        'description': description,
      });
      
      if (response.data != null) {
        return FlashcardDeck.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Không thể tạo bộ flashcard: $e');
    }
  }
}
