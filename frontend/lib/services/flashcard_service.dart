/// Flashcard Service - API calls aligned with backend controllers
library;

import '../models/flashcard.dart';
import 'api_service.dart';
import '../exceptions/app_exception.dart';

class FlashcardService {
  final ApiService _api = ApiService();

  Future<List<FlashcardDeck>> getDecks() async {
    try {
      final response = await _api.get('/flashcards/decks');
      if (response.data != null) {
        final list = response.data as List;
        return list
            .map((json) => FlashcardDeck.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the tai bo flashcard: $e');
    }
  }

  Future<FlashcardDeck?> getDeckById(String id) async {
    try {
      final decks = await getDecks();
      for (final deck in decks) {
        if (deck.userBookId == id) return deck;
      }
      return null;
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the tai thong tin bo flashcard: $e');
    }
  }

  Future<List<Flashcard>> getDueCards({String? deckId, int limit = 20}) async {
    try {
      final response = await _api.get('/flashcards/due');
      if (response.data == null) return [];

      Iterable<dynamic> items = response.data as List;
      if (deckId != null && deckId.isNotEmpty) {
        items = items.where((json) {
          final map = json as Map<String, dynamic>;
          final cardDeckId = map['userBookId']?.toString() ??
              map['user_book_id']?.toString() ??
              map['bookId']?.toString() ??
              map['book_id']?.toString();
          return cardDeckId == deckId;
        });
      }

      return items
          .take(limit)
          .map((json) => Flashcard.fromJson(json as Map<String, dynamic>))
          .toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the tai flashcard can on: $e');
    }
  }

  Future<List<Flashcard>> getCardsByDeck(String deckId) async {
    try {
      final response = await _api.get('/flashcards', queryParameters: {
        'bookId': deckId,
        'page': 0,
        'size': 100,
      });

      if (response.data != null) {
        final list = response.data['content'] as List? ?? const [];
        return list
            .map((json) => Flashcard.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the tai flashcard: $e');
    }
  }

  Future<Flashcard?> createCard({
    required String deckId,
    required String front,
    required String back,
    String? noteId,
  }) async {
    try {
      final response = await _api.post('/flashcards', data: {
        'bookId': int.tryParse(deckId),
        'question': front,
        'answer': back,
      });

      if (response.data != null) {
        return Flashcard.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the tao flashcard: $e');
    }
  }

  Future<Flashcard?> createCardFromNote(String noteId) async {
    try {
      final response = await _api.post('/flashcards/from-note/$noteId');
      if (response.data != null) {
        return Flashcard.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the tao flashcard tu ghi chu: $e');
    }
  }

  Future<Flashcard?> updateCard(String id, {String? front, String? back}) async {
    try {
      final data = <String, dynamic>{};
      if (front != null) data['question'] = front;
      if (back != null) data['answer'] = back;
      
      final response = await _api.put('/flashcards/$id', data: data);
      if (response.data != null) {
        return Flashcard.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the cap nhat flashcard: $e');
    }
  }

  Future<bool> deleteCard(String id) async {
    try {
      await _api.delete('/flashcards/$id');
      return true;
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the xoa flashcard: $e');
    }
  }

  Future<Flashcard?> submitReview(String cardId, int quality) async {
    try {
      final response = await _api.post('/flashcards/$cardId/review', data: {
        'result': _mapQualityToResult(quality),
      });

      if (response.data != null) {
        return Flashcard.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception('Khong the luu ket qua: $e');
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await _api.get('/flashcards/stats');
      final data = response.data as Map<String, dynamic>? ?? {};
      return {
        ...data,
        'streak': 0,
      };
    } on AppException {
      rethrow;
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getTodaySummary() async {
    try {
      final stats = await getStatistics();
      return {
        'reviewed': 0,
        'due': stats['dueCards'] ?? 0,
        'new': 0,
      };
    } on AppException {
      rethrow;
    } catch (_) {
      return {'reviewed': 0, 'due': 0, 'new': 0};
    }
  }

  Future<FlashcardDeck?> createDeck({
    required String name,
    required String bookId,
    String? description,
  }) async {
    throw Exception('Backend hien chua ho tro tao deck rieng.');
  }

  String _mapQualityToResult(int quality) {
    if (quality <= 0) return 'FORGOT';
    if (quality == 1) return 'REMEMBERED';
    return 'MASTERED';
  }
}
