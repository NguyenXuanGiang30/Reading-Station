package com.tramdoc.dto.request;

import com.tramdoc.entity.FlashcardReview.ReviewResult;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ReviewFlashcardRequest {
    @NotNull(message = "Kết quả review không được để trống")
    private ReviewResult result;
    
    private Integer timeSpentSeconds;
}
