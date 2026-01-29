package com.tramdoc.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserSettingsResponse {

    // Language
    private String language;

    // Reading goals
    private Integer readingGoal;
    private Boolean readingReminderEnabled;
    private String readingReminderTime;

    // Flashcard settings
    private Integer cardsPerSession;
    private Boolean reviewReminderEnabled;
    private String reviewReminderTime;

    // Privacy settings
    private String profileVisibility;
    private Boolean activitySharing;
    private Boolean allowFriendRequests;
}
