package com.tramdoc.service;

import com.tramdoc.config.AppProperties;
import com.tramdoc.exception.BadRequestException;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class FileStorageService {

    private final Path fileStorageLocation;
    private final AppProperties appProperties;

    public FileStorageService(AppProperties appProperties) {
        this.appProperties = appProperties;
        this.fileStorageLocation = Paths.get(appProperties.getStorage().getLocalDirectory()).toAbsolutePath().normalize();

        try {
            Files.createDirectories(this.fileStorageLocation);
        } catch (Exception ex) {
            throw new RuntimeException("Could not create the directory where the uploaded files will be stored.", ex);
        }
    }

    public String storeFile(MultipartFile file) {
        validateFile(file);

        // Normalize file name
        String originalFileName = StringUtils.cleanPath(file.getOriginalFilename());

        // Generate unique file name
        String extension = "";
        int i = originalFileName.lastIndexOf('.');
        if (i > 0) {
            extension = originalFileName.substring(i);
        }
        String fileName = UUID.randomUUID().toString() + extension;

        try {
            // Check if the file's name contains invalid characters
            if (originalFileName.contains("..")) {
                throw new BadRequestException("Sorry! Filename contains invalid path sequence " + fileName);
            }

            // Copy file to the target location (Replacing existing file with the same name)
            Path targetLocation = this.fileStorageLocation.resolve(fileName);
            if (!targetLocation.normalize().startsWith(fileStorageLocation)) {
                throw new BadRequestException("Invalid target file path");
            }
            try (InputStream inputStream = file.getInputStream()) {
                Files.copy(inputStream, targetLocation, StandardCopyOption.REPLACE_EXISTING);
            }

            // Return file download URI
            String fileDownloadUri = ServletUriComponentsBuilder.fromCurrentContextPath()
                    .path("/uploads/")
                    .path(fileName)
                    .toUriString();

            return fileDownloadUri;

        } catch (IOException ex) {
            throw new RuntimeException("Could not store file " + fileName + ". Please try again!", ex);
        }
    }

    private void validateFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BadRequestException("File khÃ´ng Ä‘Æ°á»£c Ä‘á»ƒ trá»‘ng");
        }

        if (file.getSize() > appProperties.getStorage().getMaxFileSizeBytes()) {
            throw new BadRequestException("File vÆ°á»£t quÃ¡ kÃ­ch thÆ°á»›c cho phÃ©p");
        }

        String originalFileName = StringUtils.cleanPath(file.getOriginalFilename());
        if (!StringUtils.hasText(originalFileName)) {
            throw new BadRequestException("TÃªn file khÃ´ng há»£p lá»‡");
        }

        String contentType = file.getContentType();
        if (!StringUtils.hasText(contentType)) {
            throw new BadRequestException("KhÃ´ng xÃ¡c Ä‘á»‹nh Ä‘Æ°á»£c loáº¡i file");
        }

        Set<String> allowedContentTypes = appProperties.getStorage().getAllowedContentTypes().stream()
                .map(type -> type.toLowerCase(Locale.ROOT))
                .collect(Collectors.toSet());
        if (!allowedContentTypes.contains(contentType.toLowerCase(Locale.ROOT))) {
            throw new BadRequestException("Loáº¡i file khÃ´ng Ä‘Æ°á»£c há»— trá»£");
        }
    }
}
