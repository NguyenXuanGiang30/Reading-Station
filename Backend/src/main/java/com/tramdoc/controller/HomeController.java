package com.tramdoc.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
public class HomeController {
    
    @GetMapping("/")
    public ResponseEntity<Map<String, Object>> home() {
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Welcome to Trạm Đọc API");
        response.put("version", "1.0.0");
        response.put("status", "running");
        response.put("endpoints", Map.of(
            "api", "/api/v1",
            "auth", "/api/v1/auth",
            "swagger", "/swagger-ui.html",
            "apiDocs", "/api-docs",
            "health", "/actuator/health"
        ));
        return ResponseEntity.ok(response);
    }
}
