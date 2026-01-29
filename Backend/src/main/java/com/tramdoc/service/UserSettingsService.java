package com.tramdoc.service;

import com.tramdoc.dto.request.UpdateUserSettingsRequest;
import com.tramdoc.dto.response.UserSettingsResponse;
import com.tramdoc.entity.User;
import com.tramdoc.entity.UserSettings;
import com.tramdoc.exception.ResourceNotFoundException;
import com.tramdoc.repository.UserRepository;
import com.tramdoc.repository.UserSettingsRepository;
import com.tramdoc.security.UserPrincipal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalTime;

@Service
public class UserSettingsService {

    @Autowired
    private UserSettingsRepository userSettingsRepository;

    @Autowired
    private UserRepository userRepository;

    private Long getCurrentUserId() {
        UserPrincipal userPrincipal = (UserPrincipal) SecurityContextHolder.getContext()
                .getAuthentication().getPrincipal();
        return userPrincipal.getId();
    }

    public UserSettingsResponse getSettings() {
        Long userId = getCurrentUserId();
        UserSettings settings = userSettingsRepository.findByUserId(userId)
                .orElseGet(() -> createDefaultSettings(userId));

        return mapToResponse(settings);
    }

    @Transactional
    public UserSettingsResponse updateSettings(UpdateUserSettingsRequest request) {
        Long userId = getCurrentUserId();
        UserSettings settings = userSettingsRepository.findByUserId(userId)
                .orElseGet(() -> createDefaultSettings(userId));

        // Language
        if (request.getLanguage() != null) {
            settings.setLanguage(request.getLanguage());
        }

        // Reading goals
        if (request.getReadingGoal() != null) {
            settings.setReadingGoal(request.getReadingGoal());
        }
        if (request.getReadingReminderEnabled() != null) {
            settings.setReadingReminderEnabled(request.getReadingReminderEnabled());
        }
        if (request.getReadingReminderTime() != null) {
            settings.setReadingReminderTime(LocalTime.parse(request.getReadingReminderTime()));
        }

        // Flashcard settings
        if (request.getCardsPerSession() != null) {
            settings.setCardsPerSession(request.getCardsPerSession());
        }
        if (request.getReviewReminderEnabled() != null) {
            settings.setReviewReminderEnabled(request.getReviewReminderEnabled());
        }
        if (request.getReviewReminderTime() != null) {
            settings.setReviewReminderTime(LocalTime.parse(request.getReviewReminderTime()));
        }

        // Privacy settings
        if (request.getProfileVisibility() != null) {
            settings.setProfileVisibility(request.getProfileVisibility());
        }
        if (request.getActivitySharing() != null) {
            settings.setActivitySharing(request.getActivitySharing());
        }
        if (request.getAllowFriendRequests() != null) {
            settings.setAllowFriendRequests(request.getAllowFriendRequests());
        }

        settings = userSettingsRepository.save(settings);
        return mapToResponse(settings);
    }

    private UserSettings createDefaultSettings(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        UserSettings settings = UserSettings.builder()
                .user(user)
                .language("vi")
                .readingGoal(24)
                .readingReminderEnabled(true)
                .readingReminderTime(LocalTime.of(20, 0))
                .cardsPerSession(20)
                .reviewReminderEnabled(true)
                .reviewReminderTime(LocalTime.of(9, 0))
                .profileVisibility("public")
                .activitySharing(true)
                .allowFriendRequests(true)
                .build();

        return userSettingsRepository.save(settings);
    }

    private UserSettingsResponse mapToResponse(UserSettings settings) {
        return UserSettingsResponse.builder()
                .language(settings.getLanguage())
                .readingGoal(settings.getReadingGoal())
                .readingReminderEnabled(settings.getReadingReminderEnabled())
                .readingReminderTime(settings.getReadingReminderTime().toString())
                .cardsPerSession(settings.getCardsPerSession())
                .reviewReminderEnabled(settings.getReviewReminderEnabled())
                .reviewReminderTime(settings.getReviewReminderTime().toString())
                .profileVisibility(settings.getProfileVisibility())
                .activitySharing(settings.getActivitySharing())
                .allowFriendRequests(settings.getAllowFriendRequests())
                .build();
    }
}
