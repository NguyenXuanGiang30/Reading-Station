/// Note Model
library;

import 'package:equatable/equatable.dart';

class Note extends Equatable {
  final String id;
  final String? userBookId;
  final String? bookTitle;
  final String content;
  final int? pageNumber;
  final String? ocrImageUrl;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  const Note({
    required this.id,
    this.userBookId,
    this.bookTitle,
    required this.content,
    this.pageNumber,
    this.ocrImageUrl,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
  });
  
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id']?.toString() ?? '',
      userBookId: json['userBookId']?.toString() ?? json['user_book_id']?.toString(),
      bookTitle: json['bookTitle'] ?? json['book_title'],
      content: json['content'] ?? '',
      pageNumber: json['pageNumber'] ?? json['page_number'],
      ocrImageUrl: json['ocrImageUrl'] ?? json['ocr_image_url'],
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
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
      'userBookId': userBookId,
      'content': content,
      'pageNumber': pageNumber,
      'ocrImageUrl': ocrImageUrl,
      'tags': tags,
    };
  }
  
  Note copyWith({
    String? id,
    String? userBookId,
    String? bookTitle,
    String? content,
    int? pageNumber,
    String? ocrImageUrl,
    List<String>? tags,
  }) {
    return Note(
      id: id ?? this.id,
      userBookId: userBookId ?? this.userBookId,
      bookTitle: bookTitle ?? this.bookTitle,
      content: content ?? this.content,
      pageNumber: pageNumber ?? this.pageNumber,
      ocrImageUrl: ocrImageUrl ?? this.ocrImageUrl,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
  
  @override
  List<Object?> get props => [
    id, userBookId, bookTitle, content, pageNumber, ocrImageUrl, tags
  ];
}
