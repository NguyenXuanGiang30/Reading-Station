package com.tramdoc.controller;

import com.tramdoc.service.FileStorageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/upload")
@Tag(name = "File Upload", description = "APIs for file upload")
public class FileUploadController {

    @Autowired
    private FileStorageService fileStorageService;

    @PostMapping
    @Operation(summary = "Upload file", description = "Upload a file and get the URL")
    public ResponseEntity<Map<String, String>> uploadFile(@RequestParam("file") MultipartFile file) {
        String fileUrl = fileStorageService.storeFile(file);

        // Return relative path for saving in DB, or full URL depending on need
        // Here we return full URL constructed by service, but we might want to store
        // relative path
        // For simplicity, let's assume the frontend will use this URL directly

        return ResponseEntity.ok(Map.of("url", fileUrl));
    }
}
