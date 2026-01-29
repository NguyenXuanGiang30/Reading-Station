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
@Table(name = "notification_settings")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class NotificationSetting {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;
    
    @Column(nullable = false)
    @Builder.Default
    private Boolean enabled = true;
    
    @Column(name = "reminder_time")
    @Builder.Default
    private LocalTime reminderTime = LocalTime.of(20, 0); // 8:00 PM
    
    @Column(name = "reminder_days", length = 20)
    @Builder.Default
    private String reminderDays = "1,2,3,4,5"; // Monday-Friday
    
    @Column(name = "sound_enabled")
    @Builder.Default
    private Boolean soundEnabled = true;
    
    @Column(name = "vibration_enabled")
    @Builder.Default
    private Boolean vibrationEnabled = true;
    
    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    
    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
