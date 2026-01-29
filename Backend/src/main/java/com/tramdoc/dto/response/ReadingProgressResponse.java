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
public class ReadingProgressResponse {
    private Long id;
    private Integer pageNumber;
    private String notes;
    private LocalDate readingDate;
    private Integer readingDurationMinutes;
    private LocalDateTime createdAt;
}
