/// Flashcard Model with SM-2 Spaced Repetition data
library;

import 'package:equatable/equatable.dart';

class Flashcard extends Equatable {
  final String id;
  final String? userBookId;
  final String? bookTitle;
  final String? noteId;
  final String question;
  final String answer;
  final int repetition;
  final double easeFactor;
  final int interval; // days
  final DateTime? nextReviewDate;
  final DateTime? lastReviewDate;
  final DateTime? createdAt;
  
  const Flashcard({
    required this.id,
    this.userBookId,
    this.bookTitle,
    this.noteId,
    required this.question,
    required this.answer,
    this.repetition = 0,
    this.easeFactor = 2.5,
    this.interval = 1,
    this.nextReviewDate,
    this.lastReviewDate,
    this.createdAt,
  });
  
  // Check if due for review
  bool get isDue {
    if (nextReviewDate == null) return true;
    return DateTime.now().isAfter(nextReviewDate!);
  }
  
  // Check if mastered (interval >= 21 days)
  bool get isMastered => interval >= 21;
  
  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id']?.toString() ?? '',
      userBookId: json['userBookId']?.toString() ?? json['user_book_id']?.toString(),
      bookTitle: json['bookTitle'] ?? json['book_title'],
      noteId: json['noteId']?.toString() ?? json['note_id']?.toString(),
      question: json['question'] ?? json['front'] ?? '',
      answer: json['answer'] ?? json['back'] ?? '',
      repetition: json['repetition'] ?? 0,
      easeFactor: (json['easeFactor'] ?? json['ease_factor'] ?? 2.5).toDouble(),
      interval: json['interval'] ?? 1,
      nextReviewDate: json['nextReviewDate'] != null 
          ? DateTime.tryParse(json['nextReviewDate']) 
          : (json['next_review_date'] != null 
              ? DateTime.tryParse(json['next_review_date']) 
              : null),
      lastReviewDate: json['lastReviewDate'] != null 
          ? DateTime.tryParse(json['lastReviewDate']) 
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userBookId': userBookId,
      'noteId': noteId,
      'question': question,
      'answer': answer,
      'repetition': repetition,
      'easeFactor': easeFactor,
      'interval': interval,
      'nextReviewDate': nextReviewDate?.toIso8601String(),
      'lastReviewDate': lastReviewDate?.toIso8601String(),
    };
  }
  
  Flashcard copyWith({
    String? id,
    String? userBookId,
    String? bookTitle,
    String? noteId,
    String? question,
    String? answer,
    int? repetition,
    double? easeFactor,
    int? interval,
    DateTime? nextReviewDate,
    DateTime? lastReviewDate,
  }) {
    return Flashcard(
      id: id ?? this.id,
      userBookId: userBookId ?? this.userBookId,
      bookTitle: bookTitle ?? this.bookTitle,
      noteId: noteId ?? this.noteId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      repetition: repetition ?? this.repetition,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastReviewDate: lastReviewDate ?? this.lastReviewDate,
      createdAt: createdAt,
    );
  }
  
  @override
  List<Object?> get props => [
    id, userBookId, bookTitle, noteId, question, answer,
    repetition, easeFactor, interval, nextReviewDate
  ];
}

/// Review Quality for SM-2 algorithm
enum ReviewQuality {
  forgot(0, 'Quên', 'Không nhớ gì'),
  remembered(3, 'Nhớ', 'Nhớ với chút khó khăn'),
  mastered(5, 'Thuộc', 'Nhớ rõ ràng');
  
  final int value;
  final String label;
  final String description;
  
  const ReviewQuality(this.value, this.label, this.description);
}

/// Flashcard Deck - Group of flashcards by book
class FlashcardDeck extends Equatable {
  final String userBookId;
  final String bookTitle;
  final String? coverUrl;
  final int totalCards;
  final int dueCards;
  final int masteredCards;
  
  const FlashcardDeck({
    required this.userBookId,
    required this.bookTitle,
    this.coverUrl,
    this.totalCards = 0,
    this.dueCards = 0,
    this.masteredCards = 0,
  });
  
  double get masteredPercent {
    if (totalCards == 0) return 0;
    return (masteredCards / totalCards * 100).clamp(0, 100);
  }
  
  factory FlashcardDeck.fromJson(Map<String, dynamic> json) {
    return FlashcardDeck(
      userBookId: json['userBookId']?.toString() ?? json['user_book_id']?.toString() ?? '',
      bookTitle: json['bookTitle'] ?? json['book_title'] ?? '',
      coverUrl: json['coverUrl'] ?? json['cover_url'],
      totalCards: json['totalCards'] ?? json['total_cards'] ?? 0,
      dueCards: json['dueCards'] ?? json['due_cards'] ?? 0,
      masteredCards: json['masteredCards'] ?? json['mastered_cards'] ?? 0,
    );
  }
  
  @override
  List<Object?> get props => [
    userBookId, bookTitle, coverUrl, totalCards, dueCards, masteredCards
  ];
}
