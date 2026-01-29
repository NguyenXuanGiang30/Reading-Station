package com.tramdoc.controller;

import com.tramdoc.dto.request.CreateBookRequest;
import com.tramdoc.dto.response.BookResponse;
import com.tramdoc.entity.Book;
import com.tramdoc.service.BookService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/books")
public class BookController {
    
    @Autowired
    private BookService bookService;
    
    @GetMapping
    public ResponseEntity<Page<BookResponse>> getAllBooks(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Book> books = bookService.getAllBooks(pageable);
        Page<BookResponse> response = books.map(this::mapToBookResponse);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<BookResponse> getBookById(@PathVariable Long id) {
        Book book = bookService.getBookById(id);
        return ResponseEntity.ok(mapToBookResponse(book));
    }
    
    @GetMapping("/search")
    public ResponseEntity<List<BookResponse>> searchBooks(@RequestParam String q) {
        List<Book> books = bookService.searchBooks(q);
        List<BookResponse> response = books.stream()
            .map(this::mapToBookResponse)
            .collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/isbn/{isbn}")
    public ResponseEntity<BookResponse> getBookByIsbn(@PathVariable String isbn) {
        Book book = bookService.getBookByIsbn(isbn);
        return ResponseEntity.ok(mapToBookResponse(book));
    }
    
    @PostMapping
    public ResponseEntity<BookResponse> createBook(@Valid @RequestBody CreateBookRequest request) {
        Book book = bookService.createBook(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(mapToBookResponse(book));
    }
    
    private BookResponse mapToBookResponse(Book book) {
        return BookResponse.builder()
            .id(book.getId())
            .title(book.getTitle())
            .author(book.getAuthor())
            .isbn(book.getIsbn())
            .coverImageUrl(book.getCoverImageUrl())
            .description(book.getDescription())
            .publisher(book.getPublisher())
            .publishedDate(book.getPublishedDate())
            .pageCount(book.getPageCount())
            .language(book.getLanguage())
            .category(book.getCategory())
            .googleBooksId(book.getGoogleBooksId())
            .build();
    }
}
