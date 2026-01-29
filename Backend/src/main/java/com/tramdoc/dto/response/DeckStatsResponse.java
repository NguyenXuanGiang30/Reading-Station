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
    private String deckName;
    private Long totalCards;
    private Long dueCards;
    private Long masteredCards;
    private Double masteryPercentage;
}
