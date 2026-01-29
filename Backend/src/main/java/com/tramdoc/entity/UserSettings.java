package com.tramdoc.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.time.LocalTime;

@Entity
@Table(name = "user_settings")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class UserSettings {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    // Language settings
    @Column(length = 5)
    @Builder.Default
    private String language = "vi";

    // Reading goals
    @Column(name = "reading_goal")
    @Builder.Default
    private Integer readingGoal = 24;

    @Column(name = "reading_reminder_enabled")
    @Builder.Default
    private Boolean readingReminderEnabled = true;

    @Column(name = "reading_reminder_time")
    @Builder.Default
    private LocalTime readingReminderTime = LocalTime.of(20, 0);

    // Flashcard settings
    @Column(name = "cards_per_session")
    @Builder.Default
    private Integer cardsPerSession = 20;

    @Column(name = "review_reminder_enabled")
    @Builder.Default
    private Boolean reviewReminderEnabled = true;

    @Column(name = "review_reminder_time")
    @Builder.Default
    private LocalTime reviewReminderTime = LocalTime.of(9, 0);

    // Privacy settings
    @Column(name = "profile_visibility")
    @Builder.Default
    private String profileVisibility = "public"; // public, friends, private

    @Column(name = "activity_sharing")
    @Builder.Default
    private Boolean activitySharing = true;

    @Column(name = "allow_friend_requests")
    @Builder.Default
    private Boolean allowFriendRequests = true;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
