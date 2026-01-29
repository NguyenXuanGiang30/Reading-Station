/// Book BLoC Events
library;

import 'package:equatable/equatable.dart';

import '../../models/book.dart';

abstract class BookEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Load all books for current user
class LoadBooks extends BookEvent {
  final ReadingStatus? status;
  final String? search;
  
  LoadBooks({this.status, this.search});
  
  @override
  List<Object?> get props => [status, search];
}

/// Load currently reading books
class LoadCurrentlyReading extends BookEvent {}

/// Load book details
class LoadBookDetail extends BookEvent {
  final String bookId;
  
  LoadBookDetail(this.bookId);
  
  @override
  List<Object?> get props => [bookId];
}

/// Add a new book
class AddBook extends BookEvent {
  final String title;
  final String author;
  final String? isbn;
  final String? publisher;
  final int? totalPages;
  final String? category;
  final String? location;
  final ReadingStatus status;
  
  AddBook({
    required this.title,
    required this.author,
    this.isbn,
    this.publisher,
    this.totalPages,
    this.category,
    this.location,
    this.status = ReadingStatus.wantToRead,
  });
  
  @override
  List<Object?> get props => [title, author, isbn, publisher, totalPages, category, location, status];
}

/// Update reading progress
class UpdateProgress extends BookEvent {
  final String bookId;
  final int currentPage;
  
  UpdateProgress({required this.bookId, required this.currentPage});
  
  @override
  List<Object?> get props => [bookId, currentPage];
}

/// Delete a book
class DeleteBook extends BookEvent {
  final String bookId;
  
  DeleteBook(this.bookId);
  
  @override
  List<Object?> get props => [bookId];
}

/// Load statistics
class LoadStatistics extends BookEvent {}
