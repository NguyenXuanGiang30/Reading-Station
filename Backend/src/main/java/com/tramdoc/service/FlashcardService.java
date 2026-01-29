package com.tramdoc.service;

import com.tramdoc.dto.request.CreateFlashcardRequest;
import com.tramdoc.dto.request.ReviewFlashcardRequest;
import com.tramdoc.dto.response.DeckStatsResponse;
import com.tramdoc.dto.response.FlashcardResponse;
import com.tramdoc.dto.response.FlashcardStatsResponse;
import com.tramdoc.entity.Book;
import com.tramdoc.entity.Flashcard;
import com.tramdoc.entity.FlashcardReview;
import com.tramdoc.entity.Note;
import com.tramdoc.entity.User;
import com.tramdoc.exception.BadRequestException;
import com.tramdoc.exception.ResourceNotFoundException;
import com.tramdoc.repository.BookRepository;
import com.tramdoc.repository.FlashcardRepository;
import com.tramdoc.repository.FlashcardReviewRepository;
import com.tramdoc.repository.NoteRepository;
import com.tramdoc.repository.UserRepository;
import com.tramdoc.security.UserPrincipal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class FlashcardService {
    
    @Autowired
    private FlashcardRepository flashcardRepository;
    
    @Autowired
    private FlashcardReviewRepository flashcardReviewRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private BookRepository bookRepository;
    
    @Autowired
    private NoteRepository noteRepository;
    
    @Autowired
    private SpacedRepetitionService spacedRepetitionService;
    
    private Long getCurrentUserId() {
        UserPrincipal userPrincipal = (UserPrincipal) SecurityContextHolder.getContext()
            .getAuthentication().getPrincipal();
        return userPrincipal.getId();
    }
    
    public List<FlashcardResponse> getDueCards() {
        Long userId = getCurrentUserId();
        LocalDate today = LocalDate.now();
        List<Flashcard> dueCards = flashcardRepository.findDueCards(userId, today);
        return dueCards.stream().map(this::mapToFlashcardResponse).toList();
    }
    
    public Page<FlashcardResponse> getUserFlashcards(Long bookId, String deckName, Pageable pageable) {
        Long userId = getCurrentUserId();
        Page<Flashcard> flashcards;
        
        if (bookId != null) {
            flashcards = flashcardRepository.findByUser_IdAndBook_Id(userId, bookId, pageable);
        } else {
            flashcards = flashcardRepository.findByUser_Id(userId, pageable);
        }
        
        // Note: Filtering by deckName would need to be done in query or after fetching
        // For now, we'll fetch all and filter in memory if needed
        return flashcards.map(this::mapToFlashcardResponse);
    }
    
    public FlashcardResponse getFlashcardById(Long flashcardId) {
        Long userId = getCurrentUserId();
        Flashcard flashcard = flashcardRepository.findById(flashcardId)
            .orElseThrow(() -> new ResourceNotFoundException("Flashcard not found"));
        
        if (!flashcard.getUser().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to access this flashcard");
        }
        
        return mapToFlashcardResponse(flashcard);
    }
    
    @Transactional
    public FlashcardResponse createFlashcard(CreateFlashcardRequest request) {
        Long userId = getCurrentUserId();
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        
        Book book = bookRepository.findById(request.getBookId())
            .orElseThrow(() -> new ResourceNotFoundException("Book not found"));
        
        String deckName = request.getDeckName() != null && !request.getDeckName().isEmpty()
            ? request.getDeckName() : book.getTitle();
        
        Flashcard flashcard = Flashcard.builder()
            .user(user)
            .book(book)
            .question(request.getQuestion())
            .answer(request.getAnswer())
            .deckName(deckName)
            .easeFactor(2.50)
            .intervalDays(1)
            .repetitions(0)
            .nextReviewDate(LocalDate.now())
            .totalReviews(0)
            .correctCount(0)
            .incorrectCount(0)
            .build();
        
        flashcard = flashcardRepository.save(flashcard);
        return mapToFlashcardResponse(flashcard);
    }
    
    @Transactional
    public FlashcardResponse createFlashcardFromNote(Long noteId) {
        Long userId = getCurrentUserId();
        Note note = noteRepository.findById(noteId)
            .orElseThrow(() -> new ResourceNotFoundException("Note not found"));
        
        if (!note.getUser().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to access this note");
        }
        
        if (note.getIsFlashcard()) {
            throw new BadRequestException("Note already converted to flashcard");
        }
        
        // Parse note content to extract question and answer
        String question = note.getTitle() != null ? note.getTitle() : extractQuestion(note.getContent());
        String answer = extractAnswer(note.getContent());
        
        String deckName = note.getBook().getTitle();
        
        Flashcard flashcard = Flashcard.builder()
            .user(note.getUser())
            .book(note.getBook())
            .note(note)
            .question(question)
            .answer(answer)
            .deckName(deckName)
            .easeFactor(2.50)
            .intervalDays(1)
            .repetitions(0)
            .nextReviewDate(LocalDate.now())
            .totalReviews(0)
            .correctCount(0)
            .incorrectCount(0)
            .build();
        
        flashcard = flashcardRepository.save(flashcard);
        
        // Mark note as converted
        note.setIsFlashcard(true);
        noteRepository.save(note);
        
        return mapToFlashcardResponse(flashcard);
    }
    
    @Transactional
    public FlashcardResponse reviewFlashcard(Long flashcardId, ReviewFlashcardRequest request) {
        Long userId = getCurrentUserId();
        Flashcard flashcard = flashcardRepository.findById(flashcardId)
            .orElseThrow(() -> new ResourceNotFoundException("Flashcard not found"));
        
        if (!flashcard.getUser().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to review this flashcard");
        }
        
        // Update flashcard using SM-2 algorithm
        spacedRepetitionService.updateFlashcardAfterReview(flashcard, request.getResult());
        flashcard = flashcardRepository.save(flashcard);
        
        // Create review record
        FlashcardReview review = FlashcardReview.builder()
            .flashcard(flashcard)
            .reviewResult(request.getResult())
            .timeSpentSeconds(request.getTimeSpentSeconds())
            .build();
        flashcardReviewRepository.save(review);
        
        return mapToFlashcardResponse(flashcard);
    }
    
    public FlashcardStatsResponse getStats() {
        Long userId = getCurrentUserId();
        LocalDate today = LocalDate.now();
        
        Page<Flashcard> allCardsPage = flashcardRepository.findByUser_Id(userId, Pageable.unpaged());
        List<Flashcard> allCards = allCardsPage.getContent();
        Long totalCards = (long) allCards.size();
        Long dueCards = flashcardRepository.countDueCards(userId, today);
        
        long masteredCards = allCards.stream()
            .filter(f -> f.getRepetitions() >= 5 && f.getCorrectCount() > f.getIncorrectCount() * 2)
            .count();
        
        double masteryPercentage = totalCards > 0 
            ? (masteredCards * 100.0 / totalCards) : 0.0;
        
        return FlashcardStatsResponse.builder()
            .totalCards(totalCards)
            .dueCards(dueCards)
            .masteredCards(masteredCards)
            .masteryPercentage(masteryPercentage)
            .build();
    }
    
    public List<DeckStatsResponse> getDeckStats() {
        Long userId = getCurrentUserId();
        LocalDate today = LocalDate.now();
        List<String> deckNames = flashcardRepository.findDistinctDeckNamesByUserId(userId);
        
        return deckNames.stream().map(deckName -> {
            List<Flashcard> allCards = flashcardRepository.findByUser_Id(userId, Pageable.unpaged()).getContent();
            List<Flashcard> deckCards = allCards.stream()
                .filter(f -> f.getDeckName().equals(deckName))
                .toList();
            
            long totalCards = deckCards.size();
            long dueCards = deckCards.stream()
                .filter(f -> f.getNextReviewDate().isBefore(today) || f.getNextReviewDate().isEqual(today))
                .count();
            long masteredCards = deckCards.stream()
                .filter(f -> f.getRepetitions() >= 5 && f.getCorrectCount() > f.getIncorrectCount() * 2)
                .count();
            
            double masteryPercentage = totalCards > 0 ? (masteredCards * 100.0 / totalCards) : 0.0;
            
            return DeckStatsResponse.builder()
                .deckName(deckName)
                .totalCards(totalCards)
                .dueCards(dueCards)
                .masteredCards(masteredCards)
                .masteryPercentage(masteryPercentage)
                .build();
        }).toList();
    }
    
    private String extractQuestion(String content) {
        // Try to extract heading as question
        Pattern pattern = Pattern.compile("^#+\\s+(.+)$", Pattern.MULTILINE);
        Matcher matcher = pattern.matcher(content);
        if (matcher.find()) {
            return matcher.group(1);
        }
        // Otherwise use first line
        String[] lines = content.split("\n");
        return lines.length > 0 ? lines[0] : "Question";
    }
    
    private String extractAnswer(String content) {
        // Remove heading and return rest as answer
        String answer = content.replaceAll("^#+\\s+.+$", "").trim();
        return answer.isEmpty() ? content : answer;
    }
    
    private FlashcardResponse mapToFlashcardResponse(Flashcard flashcard) {
        return FlashcardResponse.builder()
            .id(flashcard.getId())
            .bookId(flashcard.getBook().getId())
            .bookTitle(flashcard.getBook().getTitle())
            .question(flashcard.getQuestion())
            .answer(flashcard.getAnswer())
            .deckName(flashcard.getDeckName())
            .easeFactor(flashcard.getEaseFactor())
            .intervalDays(flashcard.getIntervalDays())
            .repetitions(flashcard.getRepetitions())
            .nextReviewDate(flashcard.getNextReviewDate())
            .lastReviewDate(flashcard.getLastReviewDate())
            .totalReviews(flashcard.getTotalReviews())
            .correctCount(flashcard.getCorrectCount())
            .incorrectCount(flashcard.getIncorrectCount())
            .createdAt(flashcard.getCreatedAt())
            .updatedAt(flashcard.getUpdatedAt())
            .build();
    }
}
