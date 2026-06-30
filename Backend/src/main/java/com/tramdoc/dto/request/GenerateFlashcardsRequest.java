package com.tramdoc.dto.request;

import lombok.Data;

@Data
public class GenerateFlashcardsRequest {
    private Long noteId;
    private Long bookId;
    private int count = 5;
}
