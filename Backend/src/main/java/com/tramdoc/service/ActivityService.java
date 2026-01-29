package com.tramdoc.service;

import com.tramdoc.dto.request.CreateCommentRequest;
import com.tramdoc.dto.response.ActivityResponse;
import com.tramdoc.dto.response.CommentResponse;
import com.tramdoc.entity.Activity;
import com.tramdoc.entity.Activity.ActivityType;
import com.tramdoc.entity.ActivityComment;
import com.tramdoc.entity.ActivityLike;
import com.tramdoc.entity.User;
import com.tramdoc.exception.BadRequestException;
import com.tramdoc.exception.ResourceNotFoundException;
import com.tramdoc.repository.ActivityCommentRepository;
import com.tramdoc.repository.ActivityLikeRepository;
import com.tramdoc.repository.ActivityRepository;
import com.tramdoc.repository.UserRepository;
import com.tramdoc.security.UserPrincipal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class ActivityService {
    
    @Autowired
    private ActivityRepository activityRepository;
    
    @Autowired
    private ActivityLikeRepository activityLikeRepository;
    
    @Autowired
    private ActivityCommentRepository activityCommentRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private FriendService friendService;
    
    private Long getCurrentUserId() {
        UserPrincipal userPrincipal = (UserPrincipal) SecurityContextHolder.getContext()
            .getAuthentication().getPrincipal();
        return userPrincipal.getId();
    }
    
    public Page<ActivityResponse> getFeed(Pageable pageable) {
        Long userId = getCurrentUserId();
        List<Long> friendIds = friendService.getFriendIds();
        friendIds.add(userId); // Include own activities
        
        Page<Activity> activities = activityRepository.findActivitiesByFriendIds(friendIds, pageable);
        return activities.map(this::mapToActivityResponse);
    }
    
    @Transactional
    public Activity createActivity(ActivityType type, Long bookId, Long userBookId, Long noteId, String metadata) {
        Long userId = getCurrentUserId();
        User user = userRepository.findById(userId).orElseThrow();
        
        Activity activity = Activity.builder()
            .user(user)
            .activityType(type)
            .metadata(metadata)
            .build();
        
        // Set related entities if provided
        if (bookId != null) {
            activity.setBook(bookRepository.findById(bookId).orElse(null));
        }
        // Note: userBookId and noteId would need their repositories injected
        
        return activityRepository.save(activity);
    }
    
    @Autowired
    private com.tramdoc.repository.BookRepository bookRepository;
    
    @Transactional
    public void likeActivity(Long activityId) {
        Long userId = getCurrentUserId();
        Activity activity = activityRepository.findById(activityId)
            .orElseThrow(() -> new ResourceNotFoundException("Activity not found"));
        
        // Check if already liked
        if (activityLikeRepository.findByActivityIdAndUserId(activityId, userId).isPresent()) {
            throw new BadRequestException("Bạn đã like hoạt động này rồi");
        }
        
        User user = userRepository.findById(userId).orElseThrow();
        ActivityLike like = ActivityLike.builder()
            .activity(activity)
            .user(user)
            .build();
        
        activityLikeRepository.save(like);
    }
    
    @Transactional
    public void unlikeActivity(Long activityId) {
        Long userId = getCurrentUserId();
        
        Optional<ActivityLike> like = activityLikeRepository.findByActivityIdAndUserId(activityId, userId);
        if (like.isEmpty()) {
            throw new BadRequestException("Bạn chưa like hoạt động này");
        }
        
        activityLikeRepository.delete(like.get());
    }
    
    @Transactional
    public CommentResponse addComment(Long activityId, CreateCommentRequest request) {
        Long userId = getCurrentUserId();
        Activity activity = activityRepository.findById(activityId)
            .orElseThrow(() -> new ResourceNotFoundException("Activity not found"));
        
        User user = userRepository.findById(userId).orElseThrow();
        
        ActivityComment comment = ActivityComment.builder()
            .activity(activity)
            .user(user)
            .content(request.getContent())
            .build();
        
        comment = activityCommentRepository.save(comment);
        return mapToCommentResponse(comment);
    }
    
    public List<CommentResponse> getComments(Long activityId) {
        activityRepository.findById(activityId)
            .orElseThrow(() -> new ResourceNotFoundException("Activity not found"));
        
        List<ActivityComment> comments = activityCommentRepository.findByActivityIdOrderByCreatedAtDesc(activityId);
        return comments.stream()
            .map(this::mapToCommentResponse)
            .collect(Collectors.toList());
    }
    
    private ActivityResponse mapToActivityResponse(Activity activity) {
        Long likeCount = activityLikeRepository.countByActivityId(activity.getId());
        Long commentCount = activityCommentRepository.countByActivityId(activity.getId());
        
        return ActivityResponse.builder()
            .id(activity.getId())
            .userId(activity.getUser().getId())
            .userName(activity.getUser().getFullName())
            .userAvatarUrl(activity.getUser().getAvatarUrl())
            .activityType(activity.getActivityType())
            .bookId(activity.getBook() != null ? activity.getBook().getId() : null)
            .bookTitle(activity.getBook() != null ? activity.getBook().getTitle() : null)
            .bookCoverUrl(activity.getBook() != null ? activity.getBook().getCoverImageUrl() : null)
            .metadata(activity.getMetadata())
            .likeCount(likeCount)
            .commentCount(commentCount)
            .createdAt(activity.getCreatedAt())
            .build();
    }
    
    private CommentResponse mapToCommentResponse(ActivityComment comment) {
        return CommentResponse.builder()
            .id(comment.getId())
            .activityId(comment.getActivity().getId())
            .userId(comment.getUser().getId())
            .userName(comment.getUser().getFullName())
            .userAvatarUrl(comment.getUser().getAvatarUrl())
            .content(comment.getContent())
            .createdAt(comment.getCreatedAt())
            .build();
    }
}
