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
import java.util.Optional;
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

        if (status == FriendStatus.PENDING) {
            friendships = friendRepository.findByFriendIdAndStatus(userId, status, pageable);
        } else {
            friendships = friendRepository.findByParticipantIdAndStatus(userId, status, pageable);
        }

        final Long currentUserId = userId;
        return friendships.map(friendship -> mapToFriendResponse(friendship, currentUserId));
    }

    @Transactional
    public void sendFriendRequest(Long friendId) {
        Long userId = getCurrentUserId();

        if (userId.equals(friendId)) {
            throw new BadRequestException("KhÃ´ng thá»ƒ káº¿t báº¡n vá»›i chÃ­nh mÃ¬nh");
        }

        User friend = userRepository.findById(friendId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));

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
    public void acceptFriendRequest(Long friendshipIdOrFriendId) {
        Long userId = getCurrentUserId();
        Friend friendship = friendRepository.findById(friendshipIdOrFriendId)
            .filter(candidate -> candidate.getFriend().getId().equals(userId))
            .or(() -> friendRepository.findByUserIdAndFriendId(friendshipIdOrFriendId, userId))
            .orElseThrow(() -> new ResourceNotFoundException("Friend request not found"));

        if (!friendship.getFriend().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to accept this request");
        }

        friendship.setStatus(FriendStatus.ACCEPTED);
        friendRepository.save(friendship);
    }

    @Transactional
    public void deleteFriend(Long friendshipIdOrFriendId) {
        Long userId = getCurrentUserId();
        Friend friendship = friendRepository.findById(friendshipIdOrFriendId)
            .filter(candidate -> belongsToUser(candidate, userId))
            .or(() -> friendRepository.findByUserIdAndFriendId(userId, friendshipIdOrFriendId))
            .or(() -> friendRepository.findByUserIdAndFriendId(friendshipIdOrFriendId, userId))
            .orElseThrow(() -> new ResourceNotFoundException("Friendship not found"));

        if (!belongsToUser(friendship, userId)) {
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

        Friend friendship = findFriendshipBetween(userId, friendId)
            .filter(f -> f.getStatus() == FriendStatus.ACCEPTED)
            .orElseThrow(() -> new BadRequestException("Báº¡n chÆ°a káº¿t báº¡n vá»›i ngÆ°á»i nÃ y"));

        User friend = userRepository.findById(friendId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        UserResponse response = userService.mapToUserResponse(friend);
        response.setFriendshipId(friendship.getId());
        response.setFriendshipStatus(friendship.getStatus().name());
        return response;
    }

    public List<UserBookResponse> getFriendBooks(Long friendId) {
        Long userId = getCurrentUserId();

        boolean areFriends = findFriendshipBetween(userId, friendId)
            .filter(f -> f.getStatus() == FriendStatus.ACCEPTED)
            .isPresent();

        if (!areFriends) {
            throw new BadRequestException("Báº¡n chÆ°a káº¿t báº¡n vá»›i ngÆ°á»i nÃ y");
        }

        List<UserBook> userBooks = userBookRepository.findByUserId(friendId);
        return userBooks.stream()
            .map(this::mapToUserBookResponse)
            .collect(Collectors.toList());
    }

    private Optional<Friend> findFriendshipBetween(Long userId, Long friendId) {
        return friendRepository.findByUserIdAndFriendId(userId, friendId)
            .or(() -> friendRepository.findByUserIdAndFriendId(friendId, userId));
    }

    private boolean belongsToUser(Friend friendship, Long userId) {
        return friendship.getUser().getId().equals(userId) || friendship.getFriend().getId().equals(userId);
    }

    private UserResponse mapToFriendResponse(Friend friendship, Long currentUserId) {
        User friend = friendship.getUser().getId().equals(currentUserId)
            ? friendship.getFriend()
            : friendship.getUser();

        UserResponse response = userService.mapToUserResponse(friend);
        response.setFriendshipId(friendship.getId());
        response.setFriendshipStatus(friendship.getStatus().name());
        return response;
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
            .updatedAt(userBook.getUpdatedAt())
            .ownerId(userBook.getUser().getId())
            .ownerName(userBook.getUser().getFullName())
            .ownerAvatarUrl(userBook.getUser().getAvatarUrl())
            .progressPercentage(progressPercentage)
            .build();
    }
}
