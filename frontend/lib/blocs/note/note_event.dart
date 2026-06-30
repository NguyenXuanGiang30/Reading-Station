import 'package:equatable/equatable.dart';

abstract class NoteEvent extends Equatable {
  const NoteEvent();

  @override
  List<Object?> get props => [];
}

class NotesLoadRequested extends NoteEvent {
  final String? bookId;

  const NotesLoadRequested({this.bookId});

  @override
  List<Object?> get props => [bookId];
}

class NoteAddRequested extends NoteEvent {
  final String bookId;
  final String content;
  final int? pageNumber;
  final String? ocrImageUrl;
  final List<String> tags;

  const NoteAddRequested({
    required this.bookId,
    required this.content,
    this.pageNumber,
    this.ocrImageUrl,
    this.tags = const [],
  });

  @override
  List<Object?> get props => [bookId, content, pageNumber, ocrImageUrl, tags];
}

class NoteUpdateRequested extends NoteEvent {
  final String noteId;
  final String content;
  final int? pageNumber;
  final List<String>? tags;

  const NoteUpdateRequested({
    required this.noteId,
    required this.content,
    this.pageNumber,
    this.tags,
  });

  @override
  List<Object?> get props => [noteId, content, pageNumber, tags];
}

class NoteDeleteRequested extends NoteEvent {
  final String noteId;

  const NoteDeleteRequested(this.noteId);

  @override
  List<Object?> get props => [noteId];
}
