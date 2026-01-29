package com.tramdoc.service;

import com.tramdoc.dto.request.CreateBookRequest;
import com.tramdoc.entity.Book;
import com.tramdoc.exception.ResourceNotFoundException;
import com.tramdoc.repository.BookRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class BookService {
    
    @Autowired
    private BookRepository bookRepository;
    
    @Autowired
    private GoogleBooksService googleBooksService;
    
    public Page<Book> getAllBooks(Pageable pageable) {
        return bookRepository.findAll(pageable);
    }
    
    public Book getBookById(Long id) {
        return bookRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Book not found with id: " + id));
    }
    
    public List<Book> searchBooks(String query) {
        // First search in local database
        List<Book> localBooks = bookRepository.findAll().stream()
            .filter(book -> book.getTitle().toLowerCase().contains(query.toLowerCase()) ||
                          (book.getAuthor() != null && book.getAuthor().toLowerCase().contains(query.toLowerCase())))
            .toList();
        
        // Also search Google Books API
        List<Book> googleBooks = googleBooksService.searchBooks(query, 10);
        
        // Merge and deduplicate by ISBN
        for (Book googleBook : googleBooks) {
            if (googleBook.getIsbn() != null && !googleBook.getIsbn().isEmpty()) {
                Optional<Book> existing = bookRepository.findByIsbn(googleBook.getIsbn());
                if (existing.isEmpty()) {
                    // Save new book from Google Books
                    bookRepository.save(googleBook);
                }
            }
        }
        
        return googleBooks.isEmpty() ? localBooks : googleBooks;
    }
    
    public Book getBookByIsbn(String isbn) {
        Optional<Book> existing = bookRepository.findByIsbn(isbn);
        if (existing.isPresent()) {
            return existing.get();
        }
        
        // Fetch from Google Books API
        Book book = googleBooksService.getBookByIsbn(isbn);
        if (book != null) {
            return bookRepository.save(book);
        }
        
        throw new ResourceNotFoundException("Book not found with ISBN: " + isbn);
    }
    
    @Transactional
    public Book createBook(Book book) {
        // Check if book with same ISBN already exists
        if (book.getIsbn() != null && !book.getIsbn().isEmpty()) {
            Optional<Book> existing = bookRepository.findByIsbn(book.getIsbn());
            if (existing.isPresent()) {
                return existing.get();
            }
        }
        
        return bookRepository.save(book);
    }
    
    @Transactional
    public Book createBook(CreateBookRequest request) {
        // Check if book with same ISBN already exists
        if (request.getIsbn() != null && !request.getIsbn().isEmpty()) {
            Optional<Book> existing = bookRepository.findByIsbn(request.getIsbn());
            if (existing.isPresent()) {
                return existing.get();
            }
        }
        
        Book book = Book.builder()
            .title(request.getTitle())
            .author(request.getAuthor())
            .isbn(request.getIsbn())
            .coverImageUrl(request.getCoverImageUrl())
            .description(request.getDescription())
            .publisher(request.getPublisher())
            .publishedDate(request.getPublishedDate())
            .pageCount(request.getPageCount())
            .language(request.getLanguage() != null ? request.getLanguage() : "vi")
            .category(request.getCategory())
            .build();
        
        return bookRepository.save(book);
    }
}
