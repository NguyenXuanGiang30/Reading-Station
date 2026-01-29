package com.tramdoc.service;

import com.tramdoc.dto.request.CreateNoteRequest;
import com.tramdoc.dto.request.UpdateNoteRequest;
import com.tramdoc.dto.response.NoteResponse;
import com.tramdoc.entity.Book;
import com.tramdoc.entity.Note;
import com.tramdoc.entity.User;
import com.tramdoc.exception.BadRequestException;
import com.tramdoc.exception.ResourceNotFoundException;
import com.tramdoc.repository.BookRepository;
import com.tramdoc.repository.NoteRepository;
import com.tramdoc.repository.UserRepository;
import com.tramdoc.security.UserPrincipal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;


@Service
public class NoteService {
    
    @Autowired
    private NoteRepository noteRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private BookRepository bookRepository;
    
    private Long getCurrentUserId() {
        UserPrincipal userPrincipal = (UserPrincipal) SecurityContextHolder.getContext()
            .getAuthentication().getPrincipal();
        return userPrincipal.getId();
    }
    
    public Page<NoteResponse> getUserNotes(Long bookId, Pageable pageable) {
        Long userId = getCurrentUserId();
        Page<Note> notes;
        
        if (bookId != null) {
            notes = noteRepository.findByUser_IdAndBook_Id(userId, bookId, pageable);
        } else {
            notes = noteRepository.findByUser_Id(userId, pageable);
        }
        
        return notes.map(this::mapToNoteResponse);
    }
    
    public NoteResponse getNoteById(Long noteId) {
        Long userId = getCurrentUserId();
        Note note = noteRepository.findById(noteId)
            .orElseThrow(() -> new ResourceNotFoundException("Note not found"));
        
        if (!note.getUser().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to access this note");
        }
        
        return mapToNoteResponse(note);
    }
    
    @Transactional
    public NoteResponse createNote(CreateNoteRequest request) {
        Long userId = getCurrentUserId();
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        
        Book book = bookRepository.findById(request.getBookId())
            .orElseThrow(() -> new ResourceNotFoundException("Book not found"));
        
        Note note = Note.builder()
            .user(user)
            .book(book)
            .title(request.getTitle())
            .content(request.getContent())
            .pageNumber(request.getPageNumber())
            .tags(request.getTags())
            .ocrImageUrl(request.getOcrImageUrl())
            .isFlashcard(false)
            .build();
        
        note = noteRepository.save(note);
        return mapToNoteResponse(note);
    }
    
    @Transactional
    public NoteResponse updateNote(Long noteId, UpdateNoteRequest request) {
        Long userId = getCurrentUserId();
        Note note = noteRepository.findById(noteId)
            .orElseThrow(() -> new ResourceNotFoundException("Note not found"));
        
        if (!note.getUser().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to update this note");
        }
        
        if (request.getTitle() != null) {
            note.setTitle(request.getTitle());
        }
        if (request.getContent() != null) {
            note.setContent(request.getContent());
        }
        if (request.getPageNumber() != null) {
            note.setPageNumber(request.getPageNumber());
        }
        if (request.getTags() != null) {
            note.setTags(request.getTags());
        }
        
        note = noteRepository.save(note);
        return mapToNoteResponse(note);
    }
    
    @Transactional
    public void deleteNote(Long noteId) {
        Long userId = getCurrentUserId();
        Note note = noteRepository.findById(noteId)
            .orElseThrow(() -> new ResourceNotFoundException("Note not found"));
        
        if (!note.getUser().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to delete this note");
        }
        
        noteRepository.delete(note);
    }
    
    public Page<NoteResponse> searchNotes(String query, Pageable pageable) {
        Long userId = getCurrentUserId();
        Page<Note> notes = noteRepository.searchNotes(userId, query, pageable);
        return notes.map(this::mapToNoteResponse);
    }
    
    private NoteResponse mapToNoteResponse(Note note) {
        return NoteResponse.builder()
            .id(note.getId())
            .bookId(note.getBook().getId())
            .bookTitle(note.getBook().getTitle())
            .title(note.getTitle())
            .content(note.getContent())
            .pageNumber(note.getPageNumber())
            .tags(note.getTags())
            .isFlashcard(note.getIsFlashcard())
            .ocrImageUrl(note.getOcrImageUrl())
            .createdAt(note.getCreatedAt())
            .updatedAt(note.getUpdatedAt())
            .build();
    }
}
