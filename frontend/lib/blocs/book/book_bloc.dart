/// Book BLoC - Manages book state with API calls
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/book.dart';
import '../../services/book_service.dart';
import 'book_event.dart';
import 'book_state.dart';

class BookBloc extends Bloc<BookEvent, BookState> {
  final BookService _bookService;
  
  BookBloc({BookService? bookService}) 
      : _bookService = bookService ?? BookService(),
        super(BookInitial()) {
    on<LoadBooks>(_onLoadBooks);
    on<LoadCurrentlyReading>(_onLoadCurrentlyReading);
    on<LoadBookDetail>(_onLoadBookDetail);
    on<AddBook>(_onAddBook);
    on<UpdateProgress>(_onUpdateProgress);
    on<DeleteBook>(_onDeleteBook);
    on<LoadStatistics>(_onLoadStatistics);
  }
  
  Future<void> _onLoadBooks(
    LoadBooks event,
    Emitter<BookState> emit,
  ) async {
    emit(BookLoading());
    try {
      final books = await _bookService.getMyBooks(
        status: event.status,
        search: event.search,
      );
      emit(BooksLoaded(books, currentFilter: event.status));
    } catch (e) {
      emit(BookError(e.toString()));
    }
  }
  
  Future<void> _onLoadCurrentlyReading(
    LoadCurrentlyReading event,
    Emitter<BookState> emit,
  ) async {
    try {
      final books = await _bookService.getCurrentlyReading();
      emit(CurrentlyReadingLoaded(books));
    } catch (e) {
      emit(BookError(e.toString()));
    }
  }
  
  Future<void> _onLoadBookDetail(
    LoadBookDetail event,
    Emitter<BookState> emit,
  ) async {
    emit(BookLoading());
    try {
      final book = await _bookService.getBookById(event.bookId);
      if (book != null) {
        emit(BookDetailLoaded(book));
      } else {
        emit(BookError('Không tìm thấy sách'));
      }
    } catch (e) {
      emit(BookError(e.toString()));
    }
  }
  
  Future<void> _onAddBook(
    AddBook event,
    Emitter<BookState> emit,
  ) async {
    emit(BookLoading());
    try {
      final book = await _bookService.addBook(
        title: event.title,
        author: event.author,
        isbn: event.isbn,
        publisher: event.publisher,
        totalPages: event.totalPages,
        category: event.category,
        location: event.location,
        status: event.status,
      );
      
      if (book != null) {
        emit(BookOperationSuccess('Đã thêm sách thành công'));
      } else {
        emit(BookError('Không thể thêm sách'));
      }
    } catch (e) {
      emit(BookError(e.toString()));
    }
  }
  
  Future<void> _onUpdateProgress(
    UpdateProgress event,
    Emitter<BookState> emit,
  ) async {
    try {
      await _bookService.updateProgress(event.bookId, event.currentPage);
      emit(BookOperationSuccess('Đã cập nhật tiến độ'));
    } catch (e) {
      emit(BookError(e.toString()));
    }
  }
  
  Future<void> _onDeleteBook(
    DeleteBook event,
    Emitter<BookState> emit,
  ) async {
    try {
      await _bookService.deleteBook(event.bookId);
      emit(BookOperationSuccess('Đã xóa sách'));
    } catch (e) {
      emit(BookError(e.toString()));
    }
  }
  
  Future<void> _onLoadStatistics(
    LoadStatistics event,
    Emitter<BookState> emit,
  ) async {
    try {
      final stats = await _bookService.getStatistics();
      emit(StatisticsLoaded(
        totalBooks: stats['totalBooks'] ?? 0,
        totalPages: stats['totalPages'] ?? 0,
        totalNotes: stats['totalNotes'] ?? 0,
        currentStreak: stats['currentStreak'] ?? 0,
      ));
    } catch (e) {
      // Return default stats on error
      emit(StatisticsLoaded());
    }
  }
}
