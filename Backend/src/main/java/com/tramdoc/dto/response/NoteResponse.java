package com.tramdoc.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NoteResponse {
    private Long id;
    private Long bookId;
    private String bookTitle;
    private String title;
    private String content;
    private Integer pageNumber;
    private String tags;
    private Boolean isFlashcard;
    private String ocrImageUrl;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
