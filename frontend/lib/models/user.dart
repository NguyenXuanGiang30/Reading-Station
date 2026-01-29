/// User Model
library;

import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? bio;
  final DateTime? createdAt;
  final int booksRead;
  final int notesCreated;
  final int flashcardsLearned;
  final int currentStreak;
  
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.bio,
    this.createdAt,
    this.booksRead = 0,
    this.notesCreated = 0,
    this.flashcardsLearned = 0,
    this.currentStreak = 0,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
      bio: json['bio'],
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : null,
      booksRead: json['booksRead'] ?? json['books_read'] ?? 0,
      notesCreated: json['notesCreated'] ?? json['notes_created'] ?? 0,
      flashcardsLearned: json['flashcardsLearned'] ?? json['flashcards_learned'] ?? 0,
      currentStreak: json['currentStreak'] ?? json['current_streak'] ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'createdAt': createdAt?.toIso8601String(),
      'booksRead': booksRead,
      'notesCreated': notesCreated,
      'flashcardsLearned': flashcardsLearned,
      'currentStreak': currentStreak,
    };
  }
  
  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? bio,
    DateTime? createdAt,
    int? booksRead,
    int? notesCreated,
    int? flashcardsLearned,
    int? currentStreak,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      booksRead: booksRead ?? this.booksRead,
      notesCreated: notesCreated ?? this.notesCreated,
      flashcardsLearned: flashcardsLearned ?? this.flashcardsLearned,
      currentStreak: currentStreak ?? this.currentStreak,
    );
  }
  
  @override
  List<Object?> get props => [
    id, email, fullName, avatarUrl, bio, createdAt,
    booksRead, notesCreated, flashcardsLearned, currentStreak
  ];
}
