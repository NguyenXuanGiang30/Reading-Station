package com.tramdoc.dto.request;

import lombok.Data;

@Data
public class UpdateNotificationSettingRequest {
    private Boolean enabled;
    private String reminderTime; // Format: "HH:mm"
    private String reminderDays; // Comma-separated: "1,2,3,4,5"
    private Boolean soundEnabled;
    private Boolean vibrationEnabled;
}
