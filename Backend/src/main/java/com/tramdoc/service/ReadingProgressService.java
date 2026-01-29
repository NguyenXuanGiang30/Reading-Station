package com.tramdoc.service;

import com.tramdoc.dto.request.UpdateProgressRequest;
import com.tramdoc.dto.response.ReadingProgressResponse;
import com.tramdoc.entity.ReadingProgress;
import com.tramdoc.entity.UserBook;
import com.tramdoc.exception.BadRequestException;
import com.tramdoc.exception.ResourceNotFoundException;
import com.tramdoc.repository.ReadingProgressRepository;
import com.tramdoc.repository.UserBookRepository;
import com.tramdoc.security.UserPrincipal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;

@Service
public class ReadingProgressService {
    
    @Autowired
    private ReadingProgressRepository readingProgressRepository;
    
    @Autowired
    private UserBookRepository userBookRepository;
    
    private Long getCurrentUserId() {
        UserPrincipal userPrincipal = (UserPrincipal) SecurityContextHolder.getContext()
            .getAuthentication().getPrincipal();
        return userPrincipal.getId();
    }
    
    @Transactional
    public ReadingProgressResponse updateProgress(Long userBookId, UpdateProgressRequest request) {
        Long userId = getCurrentUserId();
        UserBook userBook = userBookRepository.findById(userBookId)
            .orElseThrow(() -> new ResourceNotFoundException("User book not found"));
        
        if (!userBook.getUser().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to update this progress");
        }
        
        // Update user book current page
        userBook.setCurrentPage(request.getPageNumber());
        if (userBook.getTotalPages() == null && userBook.getBook().getPageCount() != null) {
            userBook.setTotalPages(userBook.getBook().getPageCount());
        }
        userBookRepository.save(userBook);
        
        // Create reading progress record
        ReadingProgress progress = ReadingProgress.builder()
            .userBook(userBook)
            .pageNumber(request.getPageNumber())
            .notes(request.getNotes())
            .readingDate(request.getReadingDate() != null ? request.getReadingDate() : LocalDate.now())
            .readingDurationMinutes(request.getReadingDurationMinutes())
            .build();
        
        progress = readingProgressRepository.save(progress);
        return mapToResponse(progress);
    }
    
    public Page<ReadingProgressResponse> getProgressHistory(Long userBookId, Pageable pageable) {
        Long userId = getCurrentUserId();
        UserBook userBook = userBookRepository.findById(userBookId)
            .orElseThrow(() -> new ResourceNotFoundException("User book not found"));
        
        if (!userBook.getUser().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to view this progress");
        }
        
        Page<ReadingProgress> progressList = readingProgressRepository
            .findByUserBookIdOrderByReadingDateDesc(userBookId, pageable);
        
        return progressList.map(this::mapToResponse);
    }
    
    private ReadingProgressResponse mapToResponse(ReadingProgress progress) {
        return ReadingProgressResponse.builder()
            .id(progress.getId())
            .pageNumber(progress.getPageNumber())
            .notes(progress.getNotes())
            .readingDate(progress.getReadingDate())
            .readingDurationMinutes(progress.getReadingDurationMinutes())
            .createdAt(progress.getCreatedAt())
            .build();
    }
}
