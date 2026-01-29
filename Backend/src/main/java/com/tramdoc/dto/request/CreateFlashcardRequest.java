package com.tramdoc.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateFlashcardRequest {
    @NotNull(message = "Book ID không được để trống")
    private Long bookId;
    
    @NotBlank(message = "Câu hỏi không được để trống")
    private String question;
    
    @NotBlank(message = "Câu trả lời không được để trống")
    private String answer;
    
    private String deckName;
}
