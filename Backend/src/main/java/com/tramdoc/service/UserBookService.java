package com.tramdoc.service;

import com.tramdoc.dto.request.AddUserBookRequest;
import com.tramdoc.dto.request.UpdateUserBookRequest;
import com.tramdoc.dto.response.BookResponse;
import com.tramdoc.dto.response.UserBookResponse;
import com.tramdoc.dto.response.UserBookStatsResponse;
import com.tramdoc.entity.Book;
import com.tramdoc.entity.ReadingProgress;
import com.tramdoc.entity.User;
import com.tramdoc.entity.UserBook;
import com.tramdoc.entity.UserBook.BookStatus;
import com.tramdoc.exception.BadRequestException;
import com.tramdoc.exception.ResourceNotFoundException;
import com.tramdoc.repository.BookRepository;
import com.tramdoc.repository.ReadingProgressRepository;
import com.tramdoc.repository.UserBookRepository;
import com.tramdoc.repository.UserRepository;
import com.tramdoc.security.UserPrincipal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class UserBookService {
    
    @Autowired
    private UserBookRepository userBookRepository;
    
    @Autowired
    private BookRepository bookRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private ReadingProgressRepository readingProgressRepository;
    
    @Autowired
    private FriendService friendService;
    
    private Long getCurrentUserId() {
        UserPrincipal userPrincipal = (UserPrincipal) SecurityContextHolder.getContext()
            .getAuthentication().getPrincipal();
        return userPrincipal.getId();
    }
    
    public Page<UserBookResponse> getUserBooks(BookStatus status, Pageable pageable) {
        Long userId = getCurrentUserId();
        Page<UserBook> userBooks;
        
        if (status != null) {
            userBooks = userBookRepository.findByUserIdAndStatus(userId, status, pageable);
        } else {
            userBooks = userBookRepository.findByUserId(userId, pageable);
        }
        
        return userBooks.map(this::mapToUserBookResponse);
    }
    
    public UserBookResponse getUserBookById(Long userBookId) {
        Long userId = getCurrentUserId();
        UserBook userBook = userBookRepository.findById(userBookId)
            .orElseThrow(() -> new ResourceNotFoundException("User book not found"));
        
        if (!userBook.getUser().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to access this book");
        }
        
        return mapToUserBookResponse(userBook);
    }
    
    @Transactional
    public UserBookResponse addUserBook(AddUserBookRequest request) {
        Long userId = getCurrentUserId();
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        
        Book book = bookRepository.findById(request.getBookId())
            .orElseThrow(() -> new ResourceNotFoundException("Book not found"));
        
        // Check if already exists
        if (userBookRepository.existsByUserIdAndBookId(userId, request.getBookId())) {
            UserBook existing = userBookRepository.findByUserIdAndBookId(userId, request.getBookId())
                .orElseThrow();
            return mapToUserBookResponse(existing);
        }
        
        UserBook userBook = UserBook.builder()
            .user(user)
            .book(book)
            .status(request.getStatus())
            .location(request.getLocation())
            .currentPage(0)
            .totalPages(book.getPageCount())
            .build();
        
        if (request.getStatus() == BookStatus.READING) {
            userBook.setStartedAt(LocalDate.now());
        }
        
        userBook = userBookRepository.save(userBook);
        return mapToUserBookResponse(userBook);
    }
    
    @Transactional
    public UserBookResponse updateUserBook(Long userBookId, UpdateUserBookRequest request) {
        Long userId = getCurrentUserId();
        UserBook userBook = userBookRepository.findById(userBookId)
            .orElseThrow(() -> new ResourceNotFoundException("User book not found"));
        
        if (!userBook.getUser().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to update this book");
        }
        
        if (request.getStatus() != null) {
            userBook.setStatus(request.getStatus());
            if (request.getStatus() == BookStatus.READING && userBook.getStartedAt() == null) {
                userBook.setStartedAt(LocalDate.now());
            }
            if (request.getStatus() == BookStatus.READ) {
                userBook.setCompletedAt(LocalDate.now());
            }
        }
        
        if (request.getCurrentPage() != null) {
            userBook.setCurrentPage(request.getCurrentPage());
        }
        
        if (request.getTotalPages() != null) {
            userBook.setTotalPages(request.getTotalPages());
        }
        
        if (request.getRating() != null) {
            if (request.getRating() < 1 || request.getRating() > 5) {
                throw new BadRequestException("Rating must be between 1 and 5");
            }
            userBook.setRating(request.getRating());
        }
        
        if (request.getReview() != null) {
            userBook.setReview(request.getReview());
        }
        
        if (request.getLocation() != null) {
            userBook.setLocation(request.getLocation());
        }
        
        userBook = userBookRepository.save(userBook);
        return mapToUserBookResponse(userBook);
    }
    
    @Transactional
    public void deleteUserBook(Long userBookId) {
        Long userId = getCurrentUserId();
        UserBook userBook = userBookRepository.findById(userBookId)
            .orElseThrow(() -> new ResourceNotFoundException("User book not found"));
        
        if (!userBook.getUser().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to delete this book");
        }
        
        userBookRepository.delete(userBook);
    }
    
    public List<UserBookResponse> getFriendsWhoReadBook(Long userBookId) {
        Long userId = getCurrentUserId();
        UserBook userBook = userBookRepository.findById(userBookId)
            .orElseThrow(() -> new ResourceNotFoundException("User book not found"));
        
        Long bookId = userBook.getBook().getId();
        List<Long> friendIds = friendService.getFriendIds();
        
        List<UserBook> friendBooks = userBookRepository.findByBookId(bookId).stream()
            .filter(ub -> friendIds.contains(ub.getUser().getId()))
            .collect(Collectors.toList());
        
        return friendBooks.stream()
            .map(this::mapToUserBookResponse)
            .toList();
    }
    
    public UserBookStatsResponse getUserBookStats(Long userBookId) {
        Long userId = getCurrentUserId();
        UserBook userBook = userBookRepository.findById(userBookId)
            .orElseThrow(() -> new ResourceNotFoundException("User book not found"));
        
        if (!userBook.getUser().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to access this");
        }
        
        Integer currentPage = userBook.getCurrentPage() != null ? userBook.getCurrentPage() : 0;
        Integer totalPages = userBook.getTotalPages() != null ? userBook.getTotalPages() : 0;
        Integer pagesRemaining = totalPages - currentPage;
        Integer progressPercent = totalPages > 0 ? (currentPage * 100) / totalPages : 0;
        
        // Calculate days reading
        int daysReading = 0;
        if (userBook.getStartedAt() != null) {
            daysReading = (int) ChronoUnit.DAYS.between(userBook.getStartedAt(), LocalDate.now()) + 1;
        }
        
        // Calculate average pages per day
        Double averagePagesPerDay = daysReading > 0 ? (double) currentPage / daysReading : 0.0;
        
        // Calculate estimated completion date
        LocalDate estimatedCompletionDate = null;
        if (averagePagesPerDay > 0 && pagesRemaining > 0) {
            int daysToFinish = (int) Math.ceil(pagesRemaining / averagePagesPerDay);
            estimatedCompletionDate = LocalDate.now().plusDays(daysToFinish);
        }
        
        // Calculate total reading minutes
        List<ReadingProgress> progressList = readingProgressRepository.findByUserBookId(userBookId);
        Integer totalReadingMinutes = progressList.stream()
            .filter(p -> p.getReadingDurationMinutes() != null)
            .mapToInt(ReadingProgress::getReadingDurationMinutes)
            .sum();
        
        return UserBookStatsResponse.builder()
            .userBookId(userBookId)
            .currentPage(currentPage)
            .totalPages(totalPages)
            .progressPercent(progressPercent)
            .pagesRemaining(pagesRemaining)
            .averagePagesPerDay(Math.round(averagePagesPerDay * 100.0) / 100.0)
            .daysReading(daysReading)
            .estimatedCompletionDate(estimatedCompletionDate)
            .totalReadingMinutes(totalReadingMinutes)
            .build();
    }
    
    private UserBookResponse mapToUserBookResponse(UserBook userBook) {
        Book book = userBook.getBook();
        BookResponse bookResponse = BookResponse.builder()
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
        
        Double progressPercentage = null;
        if (userBook.getTotalPages() != null && userBook.getTotalPages() > 0) {
            progressPercentage = (userBook.getCurrentPage().doubleValue() / userBook.getTotalPages().doubleValue()) * 100;
        }
        
        return UserBookResponse.builder()
            .id(userBook.getId())
            .book(bookResponse)
            .status(userBook.getStatus())
            .currentPage(userBook.getCurrentPage())
            .totalPages(userBook.getTotalPages())
            .rating(userBook.getRating())
            .review(userBook.getReview())
            .location(userBook.getLocation())
            .startedAt(userBook.getStartedAt())
            .completedAt(userBook.getCompletedAt())
            .createdAt(userBook.getCreatedAt())
            .updatedAt(userBook.getUpdatedAt())
            .progressPercentage(progressPercentage)
            .build();
    }
}
