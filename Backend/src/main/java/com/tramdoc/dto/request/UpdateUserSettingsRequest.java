package com.tramdoc.dto.request;

import lombok.Data;

@Data
public class UpdateUserSettingsRequest {

    // Language
    private String language;

    // Reading goals
    private Integer readingGoal;
    private Boolean readingReminderEnabled;
    private String readingReminderTime; // Format: "HH:mm"

    // Flashcard settings
    private Integer cardsPerSession;
    private Boolean reviewReminderEnabled;
    private String reviewReminderTime; // Format: "HH:mm"

    // Privacy settings
    private String profileVisibility; // public, friends, private
    private Boolean activitySharing;
    private Boolean allowFriendRequests;
}
