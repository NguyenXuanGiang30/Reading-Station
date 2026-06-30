import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/note_service.dart';
import '../../exceptions/app_exception.dart';
import 'note_event.dart';
import 'note_state.dart';

class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final NoteService _noteService;

  NoteBloc({NoteService? noteService}) 
      : _noteService = noteService ?? NoteService(),
        super(NoteInitial()) {
    on<NotesLoadRequested>(_onNotesLoadRequested);
    on<NoteAddRequested>(_onNoteAddRequested);
    on<NoteUpdateRequested>(_onNoteUpdateRequested);
    on<NoteDeleteRequested>(_onNoteDeleteRequested);
  }

  Future<void> _onNotesLoadRequested(
      NotesLoadRequested event, Emitter<NoteState> emit) async {
    emit(NotesLoading());
    try {
      final notes = event.bookId != null
          ? await _noteService.getNotesByBook(event.bookId!)
          : await _noteService.getAllNotes();
      emit(NotesLoadSuccess(notes));
    } on AppException catch (e) {
      emit(NotesLoadFailure(e.message));
    } catch (e) {
      emit(NotesLoadFailure('Không thể tải ghi chú: $e'));
    }
  }

  Future<void> _onNoteAddRequested(
      NoteAddRequested event, Emitter<NoteState> emit) async {
    final currentState = state;
    emit(NoteOperationInProgress());
    try {
      await _noteService.createNote(
        bookId: event.bookId,
        content: event.content,
        pageNumber: event.pageNumber,
        ocrImageUrl: event.ocrImageUrl,
        tags: event.tags,
      );
      emit(const NoteOperationSuccess('Đã thêm ghi chú thành công'));
      
      // Reload notes if we were in a loaded state
      if (currentState is NotesLoadSuccess) {
        // If we are showing notes for a specific book, keep showing them
        add(NotesLoadRequested(bookId: event.bookId));
      }
    } on AppException catch (e) {
      emit(NoteOperationFailure(e.message));
      // Restore previous state
      if (currentState is NotesLoadSuccess) {
        emit(currentState);
      }
    } catch (e) {
      emit(NoteOperationFailure('Không thể thêm ghi chú: $e'));
      if (currentState is NotesLoadSuccess) {
        emit(currentState);
      }
    }
  }

  Future<void> _onNoteUpdateRequested(
      NoteUpdateRequested event, Emitter<NoteState> emit) async {
    final currentState = state;
    emit(NoteOperationInProgress());
    try {
      await _noteService.updateNote(
        event.noteId,
        content: event.content,
        pageNumber: event.pageNumber,
        tags: event.tags,
      );
      emit(const NoteOperationSuccess('Đã cập nhật ghi chú'));
      
      // We don't have the bookId here natively, but we can just reload all or let the UI handle refresh
      // A common pattern is to just reload the current view
      if (currentState is NotesLoadSuccess) {
        // We reload all notes (assuming the UI will dispatch a specific load if needed)
        add(const NotesLoadRequested());
      }
    } on AppException catch (e) {
      emit(NoteOperationFailure(e.message));
      if (currentState is NotesLoadSuccess) emit(currentState);
    } catch (e) {
      emit(NoteOperationFailure('Không thể cập nhật ghi chú: $e'));
      if (currentState is NotesLoadSuccess) emit(currentState);
    }
  }

  Future<void> _onNoteDeleteRequested(
      NoteDeleteRequested event, Emitter<NoteState> emit) async {
    final currentState = state;
    emit(NoteOperationInProgress());
    try {
      await _noteService.deleteNote(event.noteId);
      emit(const NoteOperationSuccess('Đã xóa ghi chú'));
      
      if (currentState is NotesLoadSuccess) {
        // Optimistic update
        final updatedNotes = currentState.notes.where((n) => n.id != event.noteId).toList();
        emit(NotesLoadSuccess(updatedNotes));
      }
    } on AppException catch (e) {
      emit(NoteOperationFailure(e.message));
      if (currentState is NotesLoadSuccess) emit(currentState);
    } catch (e) {
      emit(NoteOperationFailure('Không thể xóa ghi chú: $e'));
      if (currentState is NotesLoadSuccess) emit(currentState);
    }
  }
}
