package com.tramdoc.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "flashcards")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class Flashcard {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "book_id", nullable = false)
    private Book book;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "note_id")
    private Note note; // NULL nếu tạo thủ công
    
    @Column(columnDefinition = "TEXT", nullable = false)
    private String question;
    
    @Column(columnDefinition = "TEXT", nullable = false)
    private String answer;
    
    @Column(name = "deck_name", length = 255)
    @Builder.Default
    private String deckName = "default";
    
    // Spaced Repetition (SM-2 Algorithm)
    @Column(name = "ease_factor")
    @Builder.Default
    private Double easeFactor = 2.50;
    
    @Column(name = "interval_days")
    @Builder.Default
    private Integer intervalDays = 1;
    
    @Column(name = "repetitions")
    @Builder.Default
    private Integer repetitions = 0;
    
    @Column(name = "next_review_date", nullable = false)
    private LocalDate nextReviewDate;
    
    @Column(name = "last_review_date")
    private LocalDate lastReviewDate;
    
    // Review stats
    @Column(name = "total_reviews")
    @Builder.Default
    private Integer totalReviews = 0;
    
    @Column(name = "correct_count")
    @Builder.Default
    private Integer correctCount = 0;
    
    @Column(name = "incorrect_count")
    @Builder.Default
    private Integer incorrectCount = 0;
    
    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    
    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
