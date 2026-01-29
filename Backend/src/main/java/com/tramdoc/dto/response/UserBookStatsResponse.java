package com.tramdoc.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;

@Data
@Builder
public class UserBookStatsResponse {
    private Long userBookId;
    private Integer currentPage;
    private Integer totalPages;
    private Integer progressPercent;
    private Integer pagesRemaining;
    private Double averagePagesPerDay;
    private Integer daysReading;
    private LocalDate estimatedCompletionDate;
    private Integer totalReadingMinutes;
}
