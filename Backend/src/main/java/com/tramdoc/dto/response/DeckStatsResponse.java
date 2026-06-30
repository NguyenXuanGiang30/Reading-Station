package com.tramdoc.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DeckStatsResponse {
    private Long bookId;
    private String deckName;
    private String bookCoverUrl;
    private Long totalCards;
    private Long dueCards;
    private Long masteredCards;
    private Double masteryPercentage;
}
