package com.tramdoc.controller;

import com.tramdoc.dto.request.UpdateNotificationSettingRequest;
import com.tramdoc.dto.response.NotificationSettingResponse;
import com.tramdoc.service.NotificationSettingService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {
    
    @Autowired
    private NotificationSettingService notificationSettingService;
    
    @GetMapping("/settings")
    public ResponseEntity<NotificationSettingResponse> getSettings() {
        NotificationSettingResponse settings = notificationSettingService.getSettings();
        return ResponseEntity.ok(settings);
    }
    
    @PutMapping("/settings")
    public ResponseEntity<NotificationSettingResponse> updateSettings(
            @Valid @RequestBody UpdateNotificationSettingRequest request) {
        NotificationSettingResponse settings = notificationSettingService.updateSettings(request);
        return ResponseEntity.ok(settings);
    }
}
