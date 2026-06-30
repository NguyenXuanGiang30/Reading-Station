package com.tramdoc.controller;

import com.tramdoc.dto.request.ChatRequest;
import com.tramdoc.dto.request.GenerateFlashcardsRequest;
import com.tramdoc.dto.request.SummarizeNotesRequest;
import com.tramdoc.dto.response.ChatResponse;
import com.tramdoc.dto.response.FlashcardResponse;
import com.tramdoc.dto.response.GenerateFlashcardsResponse;
import com.tramdoc.security.UserPrincipal;
import com.tramdoc.service.OllamaService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/ai")
public class AiController {

    @Autowired
    private OllamaService ollamaService;

    /**
     * Health check - is Ollama running? (Public endpoint)
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        boolean available = ollamaService.isAvailable();
        return ResponseEntity.ok(Map.of(
                "status", available ? "ok" : "offline",
                "model", ollamaService.getModel(),
                "available", available
        ));
    }

    /**
     * Chat with AI assistant
     */
    @PostMapping("/chat")
    public ResponseEntity<ChatResponse> chat(@Valid @RequestBody ChatRequest request) {
        Long userId = getCurrentUserId();
        ChatResponse response = ollamaService.chatWithTools(request, userId);
        return ResponseEntity.ok(response);
    }

    /**
     * Generate flashcards from notes using AI
     */
    @PostMapping("/generate-flashcards")
    public ResponseEntity<GenerateFlashcardsResponse> generateFlashcards(
            @Valid @RequestBody GenerateFlashcardsRequest request) {
        Long userId = getCurrentUserId();
        List<FlashcardResponse> flashcards;

        if (request.getNoteId() != null) {
            flashcards = ollamaService.generateFlashcardsFromNote(
                    request.getNoteId(), request.getCount());
        } else if (request.getBookId() != null) {
            flashcards = ollamaService.generateFlashcardsFromBook(
                    request.getBookId(), userId, request.getCount());
        } else {
            return ResponseEntity.badRequest().build();
        }

        GenerateFlashcardsResponse response = GenerateFlashcardsResponse.builder()
                .flashcards(flashcards)
                .sourceNote(request.getNoteId() != null
                        ? "Note #" + request.getNoteId()
                        : "Book #" + request.getBookId())
                .build();

        return ResponseEntity.ok(response);
    }

    /**
     * Summarize all notes of a book using AI
     */
    @PostMapping("/summarize-notes")
    public ResponseEntity<Map<String, String>> summarizeNotes(
            @Valid @RequestBody SummarizeNotesRequest request) {
        Long userId = getCurrentUserId();
        String summary = ollamaService.summarizeNotes(request.getBookId(), userId);
        return ResponseEntity.ok(Map.of(
                "summary", summary,
                "model", ollamaService.getModel()
        ));
    }

    private Long getCurrentUserId() {
        UserPrincipal userPrincipal = (UserPrincipal) SecurityContextHolder.getContext()
                .getAuthentication().getPrincipal();
        return userPrincipal.getId();
    }
}
