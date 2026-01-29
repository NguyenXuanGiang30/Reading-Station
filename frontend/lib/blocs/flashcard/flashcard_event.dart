/// Flashcard BLoC Events
library;

import 'package:equatable/equatable.dart';

abstract class FlashcardEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Load all decks
class LoadDecks extends FlashcardEvent {}

/// Load cards due for review
class LoadDueCards extends FlashcardEvent {
  final String? deckId;
  final int limit;
  
  LoadDueCards({this.deckId, this.limit = 20});
  
  @override
  List<Object?> get props => [deckId, limit];
}

/// Submit review result (SM-2)
class SubmitReview extends FlashcardEvent {
  final String cardId;
  final int quality; // 0-3: Again, Hard, Good, Easy
  
  SubmitReview({required this.cardId, required this.quality});
  
  @override
  List<Object?> get props => [cardId, quality];
}

/// Load today's summary
class LoadTodaySummary extends FlashcardEvent {}

/// Create flashcard from note
class CreateFromNote extends FlashcardEvent {
  final String noteId;
  
  CreateFromNote(this.noteId);
  
  @override
  List<Object?> get props => [noteId];
}
