package com.tramdoc.controller;

import com.tramdoc.dto.request.UpdateProgressRequest;
import com.tramdoc.dto.response.ReadingProgressResponse;
import com.tramdoc.service.ReadingProgressService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/user-books/{userBookId}/progress")
public class ReadingProgressController {
    
    @Autowired
    private ReadingProgressService readingProgressService;
    
    @PostMapping
    public ResponseEntity<ReadingProgressResponse> updateProgress(
            @PathVariable Long userBookId,
            @Valid @RequestBody UpdateProgressRequest request) {
        ReadingProgressResponse response = readingProgressService.updateProgress(userBookId, request);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/history")
    public ResponseEntity<Page<ReadingProgressResponse>> getProgressHistory(
            @PathVariable Long userBookId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<ReadingProgressResponse> history = readingProgressService.getProgressHistory(userBookId, pageable);
        return ResponseEntity.ok(history);
    }
}
