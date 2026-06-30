import 'package:equatable/equatable.dart';
import '../../models/note.dart';

abstract class NoteState extends Equatable {
  const NoteState();

  @override
  List<Object?> get props => [];
}

class NoteInitial extends NoteState {}

class NotesLoading extends NoteState {}

class NotesLoadSuccess extends NoteState {
  final List<Note> notes;

  const NotesLoadSuccess(this.notes);

  @override
  List<Object?> get props => [notes];
}

class NotesLoadFailure extends NoteState {
  final String message;

  const NotesLoadFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class NoteOperationInProgress extends NoteState {}

class NoteOperationSuccess extends NoteState {
  final String message;

  const NoteOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class NoteOperationFailure extends NoteState {
  final String message;

  const NoteOperationFailure(this.message);

  @override
  List<Object?> get props => [message];
}
