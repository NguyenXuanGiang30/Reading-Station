package com.tramdoc.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationSettingResponse {
    private Boolean enabled;
    private String reminderTime;
    private String reminderDays;
    private Boolean soundEnabled;
    private Boolean vibrationEnabled;
}
