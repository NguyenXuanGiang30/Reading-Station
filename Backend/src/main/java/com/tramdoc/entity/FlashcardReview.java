package com.tramdoc.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(name = "flashcard_reviews")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class FlashcardReview {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "flashcard_id", nullable = false)
    private Flashcard flashcard;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "review_result", nullable = false)
    private ReviewResult reviewResult;
    
    @Column(name = "time_spent_seconds")
    private Integer timeSpentSeconds;
    
    @CreatedDate
    @Column(name = "review_date", updatable = false)
    private LocalDateTime reviewDate;
    
    public enum ReviewResult {
        FORGOT,
        REMEMBERED,
        MASTERED
    }
}
