package com.tramdoc.controller;

import com.tramdoc.dto.request.CreateCommentRequest;
import com.tramdoc.dto.response.ActivityResponse;
import com.tramdoc.dto.response.CommentResponse;
import com.tramdoc.service.ActivityService;
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
@RequestMapping("/api/v1/activities")
public class ActivityController {
    
    @Autowired
    private ActivityService activityService;
    
    @GetMapping("/feed")
    public ResponseEntity<Page<ActivityResponse>> getFeed(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<ActivityResponse> feed = activityService.getFeed(pageable);
        return ResponseEntity.ok(feed);
    }
    
    @PostMapping("/{activityId}/like")
    public ResponseEntity<Void> likeActivity(@PathVariable Long activityId) {
        activityService.likeActivity(activityId);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }
    
    @DeleteMapping("/{activityId}/like")
    public ResponseEntity<Void> unlikeActivity(@PathVariable Long activityId) {
        activityService.unlikeActivity(activityId);
        return ResponseEntity.noContent().build();
    }
    
    @PostMapping("/{activityId}/comments")
    public ResponseEntity<CommentResponse> addComment(
            @PathVariable Long activityId,
            @Valid @RequestBody CreateCommentRequest request) {
        CommentResponse comment = activityService.addComment(activityId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(comment);
    }
    
    @GetMapping("/{activityId}/comments")
    public ResponseEntity<List<CommentResponse>> getComments(@PathVariable Long activityId) {
        List<CommentResponse> comments = activityService.getComments(activityId);
        return ResponseEntity.ok(comments);
    }
}
