package com.tramdoc.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateNoteRequest {
    @NotNull(message = "Book ID không được để trống")
    private Long bookId;
    
    private String title;
    
    @NotBlank(message = "Nội dung ghi chú không được để trống")
    private String content;
    
    private Integer pageNumber;
    
    private String tags; // Comma-separated
    
    private String ocrImageUrl;
}
