package com.tramdoc.service;

import com.tramdoc.dto.request.CreateKeyTakeawayRequest;
import com.tramdoc.dto.request.UpdateKeyTakeawayRequest;
import com.tramdoc.dto.response.KeyTakeawayResponse;
import com.tramdoc.entity.KeyTakeaway;
import com.tramdoc.entity.UserBook;
import com.tramdoc.exception.BadRequestException;
import com.tramdoc.exception.ResourceNotFoundException;
import com.tramdoc.repository.KeyTakeawayRepository;
import com.tramdoc.repository.UserBookRepository;
import com.tramdoc.security.UserPrincipal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class KeyTakeawayService {
    
    @Autowired
    private KeyTakeawayRepository keyTakeawayRepository;
    
    @Autowired
    private UserBookRepository userBookRepository;
    
    private Long getCurrentUserId() {
        UserPrincipal userPrincipal = (UserPrincipal) SecurityContextHolder.getContext()
            .getAuthentication().getPrincipal();
        return userPrincipal.getId();
    }
    
    public List<KeyTakeawayResponse> getKeyTakeaways(Long userBookId) {
        Long userId = getCurrentUserId();
        UserBook userBook = userBookRepository.findById(userBookId)
            .orElseThrow(() -> new ResourceNotFoundException("User book not found"));
        
        if (!userBook.getUser().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to access this");
        }
        
        List<KeyTakeaway> takeaways = keyTakeawayRepository.findByUserBookIdOrderByOrderIndexAsc(userBookId);
        return takeaways.stream().map(this::mapToResponse).toList();
    }
    
    @Transactional
    public KeyTakeawayResponse createKeyTakeaway(Long userBookId, CreateKeyTakeawayRequest request) {
        Long userId = getCurrentUserId();
        UserBook userBook = userBookRepository.findById(userBookId)
            .orElseThrow(() -> new ResourceNotFoundException("User book not found"));
        
        if (!userBook.getUser().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to create this");
        }
        
        KeyTakeaway takeaway = KeyTakeaway.builder()
            .userBook(userBook)
            .content(request.getContent())
            .pageNumber(request.getPageNumber())
            .orderIndex(request.getOrderIndex() != null ? request.getOrderIndex() : 0)
            .build();
        
        takeaway = keyTakeawayRepository.save(takeaway);
        return mapToResponse(takeaway);
    }
    
    @Transactional
    public KeyTakeawayResponse updateKeyTakeaway(Long takeawayId, UpdateKeyTakeawayRequest request) {
        Long userId = getCurrentUserId();
        KeyTakeaway takeaway = keyTakeawayRepository.findById(takeawayId)
            .orElseThrow(() -> new ResourceNotFoundException("Key takeaway not found"));
        
        if (!takeaway.getUserBook().getUser().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to update this");
        }
        
        if (request.getContent() != null) {
            takeaway.setContent(request.getContent());
        }
        if (request.getPageNumber() != null) {
            takeaway.setPageNumber(request.getPageNumber());
        }
        if (request.getOrderIndex() != null) {
            takeaway.setOrderIndex(request.getOrderIndex());
        }
        
        takeaway = keyTakeawayRepository.save(takeaway);
        return mapToResponse(takeaway);
    }
    
    @Transactional
    public void deleteKeyTakeaway(Long takeawayId) {
        Long userId = getCurrentUserId();
        KeyTakeaway takeaway = keyTakeawayRepository.findById(takeawayId)
            .orElseThrow(() -> new ResourceNotFoundException("Key takeaway not found"));
        
        if (!takeaway.getUserBook().getUser().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to delete this");
        }
        
        keyTakeawayRepository.delete(takeaway);
    }
    
    @Transactional
    public List<KeyTakeawayResponse> reorderTakeaways(List<Long> takeawayIds) {
        Long userId = getCurrentUserId();
        
        for (int i = 0; i < takeawayIds.size(); i++) {
            KeyTakeaway takeaway = keyTakeawayRepository.findById(takeawayIds.get(i))
                .orElseThrow(() -> new ResourceNotFoundException("Key takeaway not found"));
            
            if (!takeaway.getUserBook().getUser().getId().equals(userId)) {
                throw new BadRequestException("You don't have permission to reorder this");
            }
            
            takeaway.setOrderIndex(i);
            keyTakeawayRepository.save(takeaway);
        }
        
        List<KeyTakeaway> takeaways = keyTakeawayRepository.findAllById(takeawayIds);
        return takeaways.stream()
            .sorted((a, b) -> a.getOrderIndex().compareTo(b.getOrderIndex()))
            .map(this::mapToResponse)
            .toList();
    }
    
    private KeyTakeawayResponse mapToResponse(KeyTakeaway takeaway) {
        return KeyTakeawayResponse.builder()
            .id(takeaway.getId())
            .content(takeaway.getContent())
            .pageNumber(takeaway.getPageNumber())
            .orderIndex(takeaway.getOrderIndex())
            .createdAt(takeaway.getCreatedAt())
            .updatedAt(takeaway.getUpdatedAt())
            .build();
    }
}
