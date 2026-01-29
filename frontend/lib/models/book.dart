/// Book Model
library;

import 'package:equatable/equatable.dart';

class Book extends Equatable {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final String? description;
  final String? isbn;
  final String? publisher;
  final int? publishedYear;
  final int totalPages;
  final String? category;
  final double? rating;
  
  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    this.description,
    this.isbn,
    this.publisher,
    this.publishedYear,
    this.totalPages = 0,
    this.category,
    this.rating,
  });
  
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      coverUrl: json['coverUrl'] ?? json['cover_url'],
      description: json['description'],
      isbn: json['isbn'],
      publisher: json['publisher'],
      publishedYear: json['publishedYear'] ?? json['published_year'],
      totalPages: json['totalPages'] ?? json['total_pages'] ?? 0,
      category: json['category'],
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'description': description,
      'isbn': isbn,
      'publisher': publisher,
      'publishedYear': publishedYear,
      'totalPages': totalPages,
      'category': category,
      'rating': rating,
    };
  }
  
  @override
  List<Object?> get props => [
    id, title, author, coverUrl, description, isbn,
    publisher, publishedYear, totalPages, category, rating
  ];
}

/// Reading Status Enum
enum ReadingStatus {
  wantToRead('WANT_TO_READ', 'Muốn đọc'),
  reading('READING', 'Đang đọc'),
  read('READ', 'Đã đọc');
  
  final String value;
  final String label;
  
  const ReadingStatus(this.value, this.label);
  
  static ReadingStatus fromString(String? value) {
    return ReadingStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ReadingStatus.wantToRead,
    );
  }
}

/// UserBook Model - User's book in library
class UserBook extends Equatable {
  final String id;
  final Book book;
  final ReadingStatus status;
  final int currentPage;
  final String? location; // Vị trí sách
  final DateTime? startDate;
  final DateTime? finishDate;
  final double? userRating;
  final String? review;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  const UserBook({
    required this.id,
    required this.book,
    required this.status,
    this.currentPage = 0,
    this.location,
    this.startDate,
    this.finishDate,
    this.userRating,
    this.review,
    this.createdAt,
    this.updatedAt,
  });
  
  // Calculate progress percentage
  double get progressPercent {
    if (book.totalPages == 0) return 0;
    return (currentPage / book.totalPages * 100).clamp(0, 100);
  }
  
  // Check if book is completed
  bool get isCompleted => status == ReadingStatus.read;
  
  factory UserBook.fromJson(Map<String, dynamic> json) {
    return UserBook(
      id: json['id']?.toString() ?? '',
      book: Book.fromJson(json['book'] ?? json),
      status: ReadingStatus.fromString(json['status']),
      currentPage: json['currentPage'] ?? json['current_page'] ?? 0,
      location: json['location'],
      startDate: json['startDate'] != null 
          ? DateTime.tryParse(json['startDate']) 
          : null,
      finishDate: json['finishDate'] != null 
          ? DateTime.tryParse(json['finishDate']) 
          : null,
      userRating: (json['userRating'] as num?)?.toDouble(),
      review: json['review'],
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book': book.toJson(),
      'status': status.value,
      'currentPage': currentPage,
      'location': location,
      'startDate': startDate?.toIso8601String(),
      'finishDate': finishDate?.toIso8601String(),
      'userRating': userRating,
      'review': review,
    };
  }
  
  UserBook copyWith({
    String? id,
    Book? book,
    ReadingStatus? status,
    int? currentPage,
    String? location,
    DateTime? startDate,
    DateTime? finishDate,
    double? userRating,
    String? review,
  }) {
    return UserBook(
      id: id ?? this.id,
      book: book ?? this.book,
      status: status ?? this.status,
      currentPage: currentPage ?? this.currentPage,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      finishDate: finishDate ?? this.finishDate,
      userRating: userRating ?? this.userRating,
      review: review ?? this.review,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
  
  @override
  List<Object?> get props => [
    id, book, status, currentPage, location,
    startDate, finishDate, userRating, review
  ];
}
