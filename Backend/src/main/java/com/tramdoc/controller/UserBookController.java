package com.tramdoc.controller;

import com.tramdoc.dto.request.AddUserBookRequest;
import com.tramdoc.dto.request.UpdateUserBookRequest;
import com.tramdoc.dto.response.UserBookResponse;
import com.tramdoc.dto.response.UserBookStatsResponse;
import com.tramdoc.entity.UserBook.BookStatus;
import com.tramdoc.service.UserBookService;
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
@RequestMapping("/api/v1/user-books")
public class UserBookController {
    
    @Autowired
    private UserBookService userBookService;
    
    @GetMapping
    public ResponseEntity<Page<UserBookResponse>> getUserBooks(
            @RequestParam(required = false) BookStatus status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<UserBookResponse> userBooks = userBookService.getUserBooks(status, pageable);
        return ResponseEntity.ok(userBooks);
    }
    
    @GetMapping("/{userBookId}")
    public ResponseEntity<UserBookResponse> getUserBookById(@PathVariable Long userBookId) {
        UserBookResponse userBook = userBookService.getUserBookById(userBookId);
        return ResponseEntity.ok(userBook);
    }
    
    @PostMapping
    public ResponseEntity<UserBookResponse> addUserBook(@Valid @RequestBody AddUserBookRequest request) {
        UserBookResponse userBook = userBookService.addUserBook(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(userBook);
    }
    
    @PutMapping("/{userBookId}")
    public ResponseEntity<UserBookResponse> updateUserBook(
            @PathVariable Long userBookId,
            @Valid @RequestBody UpdateUserBookRequest request) {
        UserBookResponse userBook = userBookService.updateUserBook(userBookId, request);
        return ResponseEntity.ok(userBook);
    }
    
    @DeleteMapping("/{userBookId}")
    public ResponseEntity<Void> deleteUserBook(@PathVariable Long userBookId) {
        userBookService.deleteUserBook(userBookId);
        return ResponseEntity.noContent().build();
    }
    
    @GetMapping("/{userBookId}/friends")
    public ResponseEntity<List<UserBookResponse>> getFriendsWhoReadBook(@PathVariable Long userBookId) {
        List<UserBookResponse> friends = userBookService.getFriendsWhoReadBook(userBookId);
        return ResponseEntity.ok(friends);
    }
    
    @GetMapping("/{userBookId}/stats")
    public ResponseEntity<UserBookStatsResponse> getUserBookStats(@PathVariable Long userBookId) {
        UserBookStatsResponse stats = userBookService.getUserBookStats(userBookId);
        return ResponseEntity.ok(stats);
    }
}
