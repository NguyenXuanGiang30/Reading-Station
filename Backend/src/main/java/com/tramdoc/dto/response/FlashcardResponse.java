package com.tramdoc.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FlashcardResponse {
    private Long id;
    private Long bookId;
    private String bookTitle;
    private String question;
    private String answer;
    private String deckName;
    private Double easeFactor;
    private Integer intervalDays;
    private Integer repetitions;
    private LocalDate nextReviewDate;
    private LocalDate lastReviewDate;
    private Integer totalReviews;
    private Integer correctCount;
    private Integer incorrectCount;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
