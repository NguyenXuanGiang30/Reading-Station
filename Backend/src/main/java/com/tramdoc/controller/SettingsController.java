package com.tramdoc.controller;

import com.tramdoc.dto.request.UpdateUserSettingsRequest;
import com.tramdoc.dto.response.UserSettingsResponse;
import com.tramdoc.service.UserSettingsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/settings")
@Tag(name = "Settings", description = "User settings management")
public class SettingsController {

    @Autowired
    private UserSettingsService userSettingsService;

    @GetMapping
    @Operation(summary = "Get user settings", description = "Get current user's app settings")
    public ResponseEntity<UserSettingsResponse> getSettings() {
        UserSettingsResponse settings = userSettingsService.getSettings();
        return ResponseEntity.ok(settings);
    }

    @PutMapping
    @Operation(summary = "Update user settings", description = "Update current user's app settings")
    public ResponseEntity<UserSettingsResponse> updateSettings(
            @Valid @RequestBody UpdateUserSettingsRequest request) {
        UserSettingsResponse settings = userSettingsService.updateSettings(request);
        return ResponseEntity.ok(settings);
    }
}
