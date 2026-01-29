package com.tramdoc.controller;

import com.tramdoc.dto.request.CreateFlashcardRequest;
import com.tramdoc.dto.request.ReviewFlashcardRequest;
import com.tramdoc.dto.response.DeckStatsResponse;
import com.tramdoc.dto.response.FlashcardResponse;
import com.tramdoc.dto.response.FlashcardStatsResponse;
import com.tramdoc.service.FlashcardService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/flashcards")
public class FlashcardController {
    
    @Autowired
    private FlashcardService flashcardService;
    
    @GetMapping("/due")
    public ResponseEntity<List<FlashcardResponse>> getDueCards() {
        List<FlashcardResponse> dueCards = flashcardService.getDueCards();
        return ResponseEntity.ok(dueCards);
    }
    
    @GetMapping
    public ResponseEntity<Page<FlashcardResponse>> getUserFlashcards(
            @RequestParam(required = false) Long bookId,
            @RequestParam(required = false) String deckName,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<FlashcardResponse> flashcards = flashcardService.getUserFlashcards(bookId, deckName, pageable);
        return ResponseEntity.ok(flashcards);
    }
    
    @GetMapping("/{flashcardId}")
    public ResponseEntity<FlashcardResponse> getFlashcardById(@PathVariable Long flashcardId) {
        FlashcardResponse flashcard = flashcardService.getFlashcardById(flashcardId);
        return ResponseEntity.ok(flashcard);
    }
    
    @PostMapping
    public ResponseEntity<FlashcardResponse> createFlashcard(@Valid @RequestBody CreateFlashcardRequest request) {
        FlashcardResponse flashcard = flashcardService.createFlashcard(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(flashcard);
    }
    
    @PostMapping("/from-note/{noteId}")
    public ResponseEntity<FlashcardResponse> createFlashcardFromNote(@PathVariable Long noteId) {
        FlashcardResponse flashcard = flashcardService.createFlashcardFromNote(noteId);
        return ResponseEntity.status(HttpStatus.CREATED).body(flashcard);
    }
    
    @PostMapping("/{flashcardId}/review")
    public ResponseEntity<FlashcardResponse> reviewFlashcard(
            @PathVariable Long flashcardId,
            @Valid @RequestBody ReviewFlashcardRequest request) {
        FlashcardResponse flashcard = flashcardService.reviewFlashcard(flashcardId, request);
        return ResponseEntity.ok(flashcard);
    }
    
    @GetMapping("/stats")
    public ResponseEntity<FlashcardStatsResponse> getStats() {
        FlashcardStatsResponse stats = flashcardService.getStats();
        return ResponseEntity.ok(stats);
    }
    
    @GetMapping("/decks")
    public ResponseEntity<List<DeckStatsResponse>> getDeckStats() {
        List<DeckStatsResponse> deckStats = flashcardService.getDeckStats();
        return ResponseEntity.ok(deckStats);
    }
}
