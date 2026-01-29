/// Book BLoC States
library;

import 'package:equatable/equatable.dart';

import '../../models/book.dart';

abstract class BookState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Initial state
class BookInitial extends BookState {}

/// Loading state
class BookLoading extends BookState {}

/// Books loaded successfully
class BooksLoaded extends BookState {
  final List<Book> books;
  final ReadingStatus? currentFilter;
  
  BooksLoaded(this.books, {this.currentFilter});
  
  @override
  List<Object?> get props => [books, currentFilter];
}

/// Currently reading books loaded
class CurrentlyReadingLoaded extends BookState {
  final List<Book> books;
  
  CurrentlyReadingLoaded(this.books);
  
  @override
  List<Object?> get props => [books];
}

/// Book detail loaded
class BookDetailLoaded extends BookState {
  final Book book;
  
  BookDetailLoaded(this.book);
  
  @override
  List<Object?> get props => [book];
}

/// Statistics loaded
class StatisticsLoaded extends BookState {
  final int totalBooks;
  final int totalPages;
  final int totalNotes;
  final int currentStreak;
  
  StatisticsLoaded({
    this.totalBooks = 0,
    this.totalPages = 0,
    this.totalNotes = 0,
    this.currentStreak = 0,
  });
  
  @override
  List<Object?> get props => [totalBooks, totalPages, totalNotes, currentStreak];
}

/// Book operation success (add, update, delete)
class BookOperationSuccess extends BookState {
  final String message;
  
  BookOperationSuccess(this.message);
  
  @override
  List<Object?> get props => [message];
}

/// Error state
class BookError extends BookState {
  final String message;
  
  BookError(this.message);
  
  @override
  List<Object?> get props => [message];
}
