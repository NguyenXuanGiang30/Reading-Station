package com.tramdoc.controller;

import com.tramdoc.dto.request.CreateNoteRequest;
import com.tramdoc.dto.request.UpdateNoteRequest;
import com.tramdoc.dto.response.FlashcardResponse;
import com.tramdoc.dto.response.NoteResponse;
import com.tramdoc.service.FlashcardService;
import com.tramdoc.service.NoteService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/notes")
public class NoteController {
    
    @Autowired
    private NoteService noteService;
    
    @Autowired
    private FlashcardService flashcardService;
    
    @GetMapping
    public ResponseEntity<Page<NoteResponse>> getUserNotes(
            @RequestParam(required = false) Long bookId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<NoteResponse> notes = noteService.getUserNotes(bookId, pageable);
        return ResponseEntity.ok(notes);
    }
    
    @GetMapping("/{noteId}")
    public ResponseEntity<NoteResponse> getNoteById(@PathVariable Long noteId) {
        NoteResponse note = noteService.getNoteById(noteId);
        return ResponseEntity.ok(note);
    }
    
    @PostMapping
    public ResponseEntity<NoteResponse> createNote(@Valid @RequestBody CreateNoteRequest request) {
        NoteResponse note = noteService.createNote(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(note);
    }
    
    @PutMapping("/{noteId}")
    public ResponseEntity<NoteResponse> updateNote(
            @PathVariable Long noteId,
            @Valid @RequestBody UpdateNoteRequest request) {
        NoteResponse note = noteService.updateNote(noteId, request);
        return ResponseEntity.ok(note);
    }
    
    @DeleteMapping("/{noteId}")
    public ResponseEntity<Void> deleteNote(@PathVariable Long noteId) {
        noteService.deleteNote(noteId);
        return ResponseEntity.noContent().build();
    }
    
    @GetMapping("/search")
    public ResponseEntity<Page<NoteResponse>> searchNotes(
            @RequestParam String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<NoteResponse> notes = noteService.searchNotes(q, pageable);
        return ResponseEntity.ok(notes);
    }
    
    @PostMapping("/{noteId}/convert-to-flashcard")
    public ResponseEntity<FlashcardResponse> convertToFlashcard(@PathVariable Long noteId) {
        FlashcardResponse flashcard = flashcardService.createFlashcardFromNote(noteId);
        return ResponseEntity.status(HttpStatus.CREATED).body(flashcard);
    }
}
