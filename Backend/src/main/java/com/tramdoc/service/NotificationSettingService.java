package com.tramdoc.service;

import com.tramdoc.dto.request.UpdateNotificationSettingRequest;
import com.tramdoc.dto.response.NotificationSettingResponse;
import com.tramdoc.entity.NotificationSetting;
import com.tramdoc.entity.User;
import com.tramdoc.exception.ResourceNotFoundException;
import com.tramdoc.repository.NotificationSettingRepository;
import com.tramdoc.repository.UserRepository;
import com.tramdoc.security.UserPrincipal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalTime;

@Service
public class NotificationSettingService {
    
    @Autowired
    private NotificationSettingRepository notificationSettingRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    private Long getCurrentUserId() {
        UserPrincipal userPrincipal = (UserPrincipal) SecurityContextHolder.getContext()
            .getAuthentication().getPrincipal();
        return userPrincipal.getId();
    }
    
    public NotificationSettingResponse getSettings() {
        Long userId = getCurrentUserId();
        NotificationSetting setting = notificationSettingRepository.findByUserId(userId)
            .orElseGet(() -> createDefaultSettings(userId));
        
        return mapToResponse(setting);
    }
    
    @Transactional
    public NotificationSettingResponse updateSettings(UpdateNotificationSettingRequest request) {
        Long userId = getCurrentUserId();
        NotificationSetting setting = notificationSettingRepository.findByUserId(userId)
            .orElseGet(() -> createDefaultSettings(userId));
        
        if (request.getEnabled() != null) {
            setting.setEnabled(request.getEnabled());
        }
        if (request.getReminderTime() != null) {
            setting.setReminderTime(LocalTime.parse(request.getReminderTime()));
        }
        if (request.getReminderDays() != null) {
            setting.setReminderDays(request.getReminderDays());
        }
        if (request.getSoundEnabled() != null) {
            setting.setSoundEnabled(request.getSoundEnabled());
        }
        if (request.getVibrationEnabled() != null) {
            setting.setVibrationEnabled(request.getVibrationEnabled());
        }
        
        setting = notificationSettingRepository.save(setting);
        return mapToResponse(setting);
    }
    
    private NotificationSetting createDefaultSettings(Long userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        
        NotificationSetting setting = NotificationSetting.builder()
            .user(user)
            .enabled(true)
            .reminderTime(LocalTime.of(20, 0))
            .reminderDays("1,2,3,4,5")
            .soundEnabled(true)
            .vibrationEnabled(true)
            .build();
        
        return notificationSettingRepository.save(setting);
    }
    
    private NotificationSettingResponse mapToResponse(NotificationSetting setting) {
        return NotificationSettingResponse.builder()
            .enabled(setting.getEnabled())
            .reminderTime(setting.getReminderTime().toString())
            .reminderDays(setting.getReminderDays())
            .soundEnabled(setting.getSoundEnabled())
            .vibrationEnabled(setting.getVibrationEnabled())
            .build();
    }
}
