package com.tramdoc.service;

import com.tramdoc.entity.Flashcard;
import com.tramdoc.entity.FlashcardReview.ReviewResult;
import org.springframework.stereotype.Service;

import java.time.LocalDate;

@Service
public class SpacedRepetitionService {
    
    // SM-2 Algorithm implementation
    public void updateFlashcardAfterReview(Flashcard flashcard, ReviewResult result) {
        int quality = getQualityFromResult(result);
        
        if (quality < 3) {
            // Forgot - Reset
            flashcard.setRepetitions(0);
            flashcard.setIntervalDays(1);
            flashcard.setEaseFactor(Math.max(1.3, flashcard.getEaseFactor() - 0.2));
            flashcard.setIncorrectCount(flashcard.getIncorrectCount() + 1);
        } else {
            // Remembered or Mastered
            flashcard.setRepetitions(flashcard.getRepetitions() + 1);
            flashcard.setCorrectCount(flashcard.getCorrectCount() + 1);
            
            if (flashcard.getRepetitions() == 1) {
                flashcard.setIntervalDays(1);
            } else if (flashcard.getRepetitions() == 2) {
                flashcard.setIntervalDays(6);
            } else {
                flashcard.setIntervalDays((int) Math.round(
                    flashcard.getIntervalDays() * flashcard.getEaseFactor()
                ));
            }
            
            // Update ease factor based on quality
            double newEaseFactor = flashcard.getEaseFactor() + 
                (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
            flashcard.setEaseFactor(Math.max(1.3, newEaseFactor));
        }
        
        // Update next review date
        flashcard.setNextReviewDate(LocalDate.now().plusDays(flashcard.getIntervalDays()));
        flashcard.setLastReviewDate(LocalDate.now());
        flashcard.setTotalReviews(flashcard.getTotalReviews() + 1);
    }
    
    private int getQualityFromResult(ReviewResult result) {
        return switch (result) {
            case FORGOT -> 0;
            case REMEMBERED -> 3;
            case MASTERED -> 5;
        };
    }
}
