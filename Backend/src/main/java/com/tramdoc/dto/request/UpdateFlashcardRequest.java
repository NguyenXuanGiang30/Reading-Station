package com.tramdoc.dto.request;

import lombok.Data;

@Data
public class UpdateFlashcardRequest {
    private String question;
    private String answer;
    private String deckName;
}
