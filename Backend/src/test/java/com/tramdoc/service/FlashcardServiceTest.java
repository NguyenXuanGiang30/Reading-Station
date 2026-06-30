package com.tramdoc.service;

import com.tramdoc.dto.request.CreateFlashcardRequest;
import com.tramdoc.dto.response.FlashcardResponse;
import com.tramdoc.entity.Book;
import com.tramdoc.entity.Flashcard;
import com.tramdoc.entity.User;
import com.tramdoc.repository.BookRepository;
import com.tramdoc.repository.FlashcardRepository;
import com.tramdoc.repository.FlashcardReviewRepository;
import com.tramdoc.repository.NoteRepository;
import com.tramdoc.repository.UserRepository;
import com.tramdoc.security.UserPrincipal;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.LocalDate;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class FlashcardServiceTest {

    @Mock
    private FlashcardRepository flashcardRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private BookRepository bookRepository;
    @Mock
    private FlashcardReviewRepository flashcardReviewRepository;
    @Mock
    private NoteRepository noteRepository;
    @Mock
    private SpacedRepetitionService spacedRepetitionService;
    
    @InjectMocks
    private FlashcardService flashcardService;

    private User testUser;
    private Book testBook;

    @BeforeEach
    void setUp() {
        testUser = User.builder()
                .id(1L)
                .email("test@email.com")
                .fullName("Test User")
                .isActive(true)
                .build();

        testBook = new Book();
        testBook.setId(10L);
        testBook.setTitle("Effective Java");

        // Mock Security Context
        UserPrincipal principal = UserPrincipal.create(testUser);
        SecurityContext context = mock(SecurityContext.class);
        when(context.getAuthentication()).thenReturn(
                new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities())
        );
        SecurityContextHolder.setContext(context);
    }

    @Test
    void testCreateFlashcard_Success() {
        // Arrange
        CreateFlashcardRequest request = new CreateFlashcardRequest();
        request.setBookId(10L);
        request.setQuestion("What is polymorphism?");
        request.setAnswer("Many forms");

        when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));
        when(bookRepository.findById(10L)).thenReturn(Optional.of(testBook));
        
        Flashcard savedCard = Flashcard.builder()
            .id(100L)
            .user(testUser)
            .book(testBook)
            .question(request.getQuestion())
            .answer(request.getAnswer())
            .deckName(testBook.getTitle())
            .easeFactor(2.5)
            .intervalDays(1)
            .repetitions(0)
            .correctCount(0)
            .incorrectCount(0)
            .totalReviews(0)
            .nextReviewDate(LocalDate.now())
            .build();
            
        when(flashcardRepository.save(any(Flashcard.class))).thenReturn(savedCard);

        // Act
        FlashcardResponse response = flashcardService.createFlashcard(request);

        // Assert
        assertNotNull(response);
        assertEquals(100L, response.getId());
        assertEquals("What is polymorphism?", response.getQuestion());
        assertEquals("Effective Java", response.getDeckName());
        verify(flashcardRepository, times(1)).save(any(Flashcard.class));
    }
}
