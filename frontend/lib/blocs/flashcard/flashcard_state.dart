/// Flashcard BLoC States
library;

import 'package:equatable/equatable.dart';

import '../../models/flashcard.dart';

abstract class FlashcardState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FlashcardInitial extends FlashcardState {}

class FlashcardLoading extends FlashcardState {}

/// Decks loaded
class DecksLoaded extends FlashcardState {
  final List<FlashcardDeck> decks;
  
  DecksLoaded(this.decks);
  
  @override
  List<Object?> get props => [decks];
}

/// Cards loaded for review
class CardsLoaded extends FlashcardState {
  final List<Flashcard> cards;
  final int currentIndex;
  
  CardsLoaded(this.cards, {this.currentIndex = 0});
  
  @override
  List<Object?> get props => [cards, currentIndex];
}

/// Review submitted successfully
class ReviewSubmitted extends FlashcardState {
  final Flashcard updatedCard;
  
  ReviewSubmitted(this.updatedCard);
  
  @override
  List<Object?> get props => [updatedCard];
}

/// Today's summary loaded
class TodaySummaryLoaded extends FlashcardState {
  final int reviewed;
  final int due;
  final int newCards;
  
  TodaySummaryLoaded({
    this.reviewed = 0,
    this.due = 0,
    this.newCards = 0,
  });
  
  @override
  List<Object?> get props => [reviewed, due, newCards];
}

/// Session completed
class SessionCompleted extends FlashcardState {
  final int total;
  final int correct;
  final int incorrect;
  
  SessionCompleted({
    required this.total,
    required this.correct,
    required this.incorrect,
  });
  
  double get accuracy => total > 0 ? (correct / total * 100) : 0;
  
  @override
  List<Object?> get props => [total, correct, incorrect];
}

class FlashcardError extends FlashcardState {
  final String message;
  
  FlashcardError(this.message);
  
  @override
  List<Object?> get props => [message];
}
