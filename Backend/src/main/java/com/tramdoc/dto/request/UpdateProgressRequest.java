package com.tramdoc.dto.request;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDate;

@Data
public class UpdateProgressRequest {
    @NotNull(message = "Sá»‘ trang khÃ´ng Ä‘Æ°á»£c Ä‘á»ƒ trá»‘ng")
    @JsonAlias("currentPage")
    private Integer pageNumber;

    private LocalDate readingDate;

    @JsonAlias("note")
    private String notes;

    @JsonAlias("readingMinutes")
    private Integer readingDurationMinutes;
}
