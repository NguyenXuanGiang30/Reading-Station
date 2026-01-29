package com.tramdoc.controller;

import com.tramdoc.dto.response.UserBookResponse;
import com.tramdoc.dto.response.UserResponse;
import com.tramdoc.entity.Friend.FriendStatus;
import com.tramdoc.service.FriendService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/friends")
public class FriendController {
    
    @Autowired
    private FriendService friendService;
    
    @GetMapping
    public ResponseEntity<Page<UserResponse>> getFriends(
            @RequestParam(required = false) FriendStatus status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<UserResponse> friends = friendService.getFriends(status, pageable);
        return ResponseEntity.ok(friends);
    }
    
    @PostMapping("/request/{friendId}")
    public ResponseEntity<Void> sendFriendRequest(@PathVariable Long friendId) {
        friendService.sendFriendRequest(friendId);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }
    
    @PutMapping("/{friendshipId}/accept")
    public ResponseEntity<Void> acceptFriendRequest(@PathVariable Long friendshipId) {
        friendService.acceptFriendRequest(friendshipId);
        return ResponseEntity.ok().build();
    }
    
    @DeleteMapping("/{friendshipId}")
    public ResponseEntity<Void> deleteFriend(@PathVariable Long friendshipId) {
        friendService.deleteFriend(friendshipId);
        return ResponseEntity.noContent().build();
    }
    
    @GetMapping("/{friendId}/profile")
    public ResponseEntity<UserResponse> getFriendProfile(@PathVariable Long friendId) {
        UserResponse profile = friendService.getFriendProfile(friendId);
        return ResponseEntity.ok(profile);
    }
    
    @GetMapping("/{friendId}/books")
    public ResponseEntity<List<UserBookResponse>> getFriendBooks(@PathVariable Long friendId) {
        List<UserBookResponse> books = friendService.getFriendBooks(friendId);
        return ResponseEntity.ok(books);
    }
}
