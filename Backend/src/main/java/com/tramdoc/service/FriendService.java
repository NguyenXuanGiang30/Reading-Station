package com.tramdoc.service;

import com.tramdoc.dto.response.BookResponse;
import com.tramdoc.dto.response.UserBookResponse;
import com.tramdoc.dto.response.UserResponse;
import com.tramdoc.entity.Friend;
import com.tramdoc.entity.Friend.FriendStatus;
import com.tramdoc.entity.User;
import com.tramdoc.entity.UserBook;
import com.tramdoc.exception.BadRequestException;
import com.tramdoc.exception.ResourceNotFoundException;
import com.tramdoc.repository.FriendRepository;
import com.tramdoc.repository.UserBookRepository;
import com.tramdoc.repository.UserRepository;
import com.tramdoc.security.UserPrincipal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class FriendService {
    
    @Autowired
    private FriendRepository friendRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private UserBookRepository userBookRepository;
    
    @Autowired
    private UserService userService;
    
    private Long getCurrentUserId() {
        UserPrincipal userPrincipal = (UserPrincipal) SecurityContextHolder.getContext()
            .getAuthentication().getPrincipal();
        return userPrincipal.getId();
    }
    
    public Page<UserResponse> getFriends(FriendStatus status, Pageable pageable) {
        Long userId = getCurrentUserId();
        Page<Friend> friendships;
        
        if (status == null) {
            status = FriendStatus.ACCEPTED;
        }
        
        friendships = friendRepository.findByUserIdAndStatus(userId, status, pageable);
        
        return friendships.map(f -> {
            User friend = f.getFriend();
            return userService.mapToUserResponse(friend);
        });
    }
    
    @Transactional
    public void sendFriendRequest(Long friendId) {
        Long userId = getCurrentUserId();
        
        if (userId.equals(friendId)) {
            throw new BadRequestException("Không thể kết bạn với chính mình");
        }
        
        User friend = userRepository.findById(friendId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        
        // Check if friendship already exists
        if (friendRepository.findByUserIdAndFriendId(userId, friendId).isPresent() ||
            friendRepository.findByUserIdAndFriendId(friendId, userId).isPresent()) {
            throw new BadRequestException("Friendship already exists");
        }
        
        Friend friendship = Friend.builder()
            .user(userRepository.findById(userId).orElseThrow())
            .friend(friend)
            .status(FriendStatus.PENDING)
            .build();
        
        friendRepository.save(friendship);
    }
    
    @Transactional
    public void acceptFriendRequest(Long friendshipId) {
        Long userId = getCurrentUserId();
        Friend friendship = friendRepository.findById(friendshipId)
            .orElseThrow(() -> new ResourceNotFoundException("Friend request not found"));
        
        if (!friendship.getFriend().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to accept this request");
        }
        
        friendship.setStatus(FriendStatus.ACCEPTED);
        friendRepository.save(friendship);
    }
    
    @Transactional
    public void deleteFriend(Long friendshipId) {
        Long userId = getCurrentUserId();
        Friend friendship = friendRepository.findById(friendshipId)
            .orElseThrow(() -> new ResourceNotFoundException("Friendship not found"));
        
        if (!friendship.getUser().getId().equals(userId) && 
            !friendship.getFriend().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to delete this friendship");
        }
        
        friendRepository.delete(friendship);
    }
    
    public List<Long> getFriendIds() {
        Long userId = getCurrentUserId();
        List<Friend> friends = friendRepository.findAcceptedFriends(userId);
        return friends.stream()
            .map(f -> f.getUser().getId().equals(userId) ? f.getFriend().getId() : f.getUser().getId())
            .collect(Collectors.toList());
    }
    
    public UserResponse getFriendProfile(Long friendId) {
        Long userId = getCurrentUserId();
        
        // Check if they are friends
        boolean areFriends = friendRepository.findByUserIdAndFriendId(userId, friendId)
            .filter(f -> f.getStatus() == FriendStatus.ACCEPTED)
            .isPresent() ||
            friendRepository.findByUserIdAndFriendId(friendId, userId)
            .filter(f -> f.getStatus() == FriendStatus.ACCEPTED)
            .isPresent();
        
        if (!areFriends) {
            throw new BadRequestException("Bạn chưa kết bạn với người này");
        }
        
        User friend = userRepository.findById(friendId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        
        return userService.mapToUserResponse(friend);
    }
    
    public List<UserBookResponse> getFriendBooks(Long friendId) {
        Long userId = getCurrentUserId();
        
        // Check if they are friends
        boolean areFriends = friendRepository.findByUserIdAndFriendId(userId, friendId)
            .filter(f -> f.getStatus() == FriendStatus.ACCEPTED)
            .isPresent() ||
            friendRepository.findByUserIdAndFriendId(friendId, userId)
            .filter(f -> f.getStatus() == FriendStatus.ACCEPTED)
            .isPresent();
        
        if (!areFriends) {
            throw new BadRequestException("Bạn chưa kết bạn với người này");
        }
        
        List<UserBook> userBooks = userBookRepository.findByUserId(friendId);
        return userBooks.stream()
            .map(this::mapToUserBookResponse)
            .collect(Collectors.toList());
    }
    
    private UserBookResponse mapToUserBookResponse(UserBook userBook) {
        com.tramdoc.entity.Book book = userBook.getBook();
        BookResponse bookResponse = BookResponse.builder()
            .id(book.getId())
            .title(book.getTitle())
            .author(book.getAuthor())
            .isbn(book.getIsbn())
            .coverImageUrl(book.getCoverImageUrl())
            .description(book.getDescription())
            .publisher(book.getPublisher())
            .publishedDate(book.getPublishedDate())
            .pageCount(book.getPageCount())
            .language(book.getLanguage())
            .category(book.getCategory())
            .googleBooksId(book.getGoogleBooksId())
            .build();
        
        Double progressPercentage = null;
        if (userBook.getTotalPages() != null && userBook.getTotalPages() > 0) {
            progressPercentage = (userBook.getCurrentPage().doubleValue() / userBook.getTotalPages().doubleValue()) * 100;
        }
        
        return UserBookResponse.builder()
            .id(userBook.getId())
            .book(bookResponse)
            .status(userBook.getStatus())
            .currentPage(userBook.getCurrentPage())
            .totalPages(userBook.getTotalPages())
            .rating(userBook.getRating())
            .review(userBook.getReview())
            .location(userBook.getLocation())
            .startedAt(userBook.getStartedAt())
            .completedAt(userBook.getCompletedAt())
            .createdAt(userBook.getCreatedAt())
            .progressPercentage(progressPercentage)
            .build();
    }
}
