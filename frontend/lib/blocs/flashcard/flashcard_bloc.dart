/// Flashcard BLoC - Manages flashcard state with API calls
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/flashcard.dart';
import '../../services/flashcard_service.dart';
import 'flashcard_event.dart';
import 'flashcard_state.dart';

class FlashcardBloc extends Bloc<FlashcardEvent, FlashcardState> {
  final FlashcardService _flashcardService;
  
  List<Flashcard> _sessionCards = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  int _incorrectCount = 0;
  
  FlashcardBloc({FlashcardService? flashcardService})
      : _flashcardService = flashcardService ?? FlashcardService(),
        super(FlashcardInitial()) {
    on<LoadDecks>(_onLoadDecks);
    on<LoadDueCards>(_onLoadDueCards);
    on<SubmitReview>(_onSubmitReview);
    on<LoadTodaySummary>(_onLoadTodaySummary);
    on<CreateFromNote>(_onCreateFromNote);
  }
  
  Future<void> _onLoadDecks(
    LoadDecks event,
    Emitter<FlashcardState> emit,
  ) async {
    emit(FlashcardLoading());
    try {
      final decks = await _flashcardService.getDecks();
      emit(DecksLoaded(decks));
    } catch (e) {
      emit(FlashcardError(e.toString()));
    }
  }
  
  Future<void> _onLoadDueCards(
    LoadDueCards event,
    Emitter<FlashcardState> emit,
  ) async {
    emit(FlashcardLoading());
    try {
      final cards = await _flashcardService.getDueCards(
        deckId: event.deckId,
        limit: event.limit,
      );
      
      // Reset session state
      _sessionCards = cards;
      _currentIndex = 0;
      _correctCount = 0;
      _incorrectCount = 0;
      
      if (cards.isEmpty) {
        emit(SessionCompleted(
          total: 0,
          correct: 0,
          incorrect: 0,
        ));
      } else {
        emit(CardsLoaded(cards, currentIndex: 0));
      }
    } catch (e) {
      emit(FlashcardError(e.toString()));
    }
  }
  
  Future<void> _onSubmitReview(
    SubmitReview event,
    Emitter<FlashcardState> emit,
  ) async {
    try {
      // Submit to API
      await _flashcardService.submitReview(event.cardId, event.quality);
      
      // Track result
      if (event.quality >= 2) {
        _correctCount++;
      } else {
        _incorrectCount++;
      }
      
      // Move to next card
      _currentIndex++;
      
      if (_currentIndex >= _sessionCards.length) {
        // Session complete
        emit(SessionCompleted(
          total: _sessionCards.length,
          correct: _correctCount,
          incorrect: _incorrectCount,
        ));
      } else {
        emit(CardsLoaded(_sessionCards, currentIndex: _currentIndex));
      }
    } catch (e) {
      emit(FlashcardError(e.toString()));
    }
  }
  
  Future<void> _onLoadTodaySummary(
    LoadTodaySummary event,
    Emitter<FlashcardState> emit,
  ) async {
    try {
      final summary = await _flashcardService.getTodaySummary();
      emit(TodaySummaryLoaded(
        reviewed: summary['reviewed'] ?? 0,
        due: summary['due'] ?? 0,
        newCards: summary['new'] ?? 0,
      ));
    } catch (e) {
      emit(TodaySummaryLoaded());
    }
  }
  
  Future<void> _onCreateFromNote(
    CreateFromNote event,
    Emitter<FlashcardState> emit,
  ) async {
    try {
      // This would call note service to create flashcard
      // For now just emit success
      emit(FlashcardInitial());
    } catch (e) {
      emit(FlashcardError(e.toString()));
    }
  }
}
