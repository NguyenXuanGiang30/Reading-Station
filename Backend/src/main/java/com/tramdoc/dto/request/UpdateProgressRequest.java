package com.tramdoc.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDate;

@Data
public class UpdateProgressRequest {
    @NotNull(message = "Số trang không được để trống")
    private Integer pageNumber;
    
    private LocalDate readingDate;
    
    private String notes;
    
    private Integer readingDurationMinutes;
}
