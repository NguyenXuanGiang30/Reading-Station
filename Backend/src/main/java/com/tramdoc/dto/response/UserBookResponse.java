package com.tramdoc.dto.response;

import com.tramdoc.entity.UserBook.BookStatus;
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
public class UserBookResponse {
    private Long id;
    private BookResponse book;
    private BookStatus status;
    private Integer currentPage;
    private Integer totalPages;
    private Integer rating;
    private String review;
    private String location;
    private LocalDate startedAt;
    private LocalDate completedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    // Calculated fields
    private Double progressPercentage;
}
