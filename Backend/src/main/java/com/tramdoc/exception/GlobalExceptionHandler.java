package com.tramdoc.exception;

import com.tramdoc.dto.response.ApiResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;
import java.util.stream.Collectors;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);
    
    // ==================== Custom Exceptions ====================
    
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiResponse<?>> handleResourceNotFoundException(ResourceNotFoundException ex) {
        ApiResponse<?> response = ApiResponse.error(
            ex.getMessage(),
            HttpStatus.NOT_FOUND.value(),
            "RESOURCE_NOT_FOUND"
        );
        return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
    }
    
    @ExceptionHandler(BadRequestException.class)
    public ResponseEntity<ApiResponse<?>> handleBadRequestException(BadRequestException ex) {
        ApiResponse<?> response = ApiResponse.error(
            ex.getMessage(),
            HttpStatus.BAD_REQUEST.value(),
            "BAD_REQUEST"
        );
        return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
    }
    
    // ==================== Validation Exceptions ====================
    
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<?>> handleValidationExceptions(MethodArgumentNotValidException ex) {
        // Collect all validation errors
        Map<String, String> errors = ex.getBindingResult().getAllErrors().stream()
            .collect(Collectors.toMap(
                error -> ((FieldError) error).getField(),
                error -> error.getDefaultMessage() != null ? error.getDefaultMessage() : "Invalid value",
                (existing, replacement) -> existing
            ));
        
        // Create a readable error message
        String errorMessage = errors.entrySet().stream()
            .map(entry -> entry.getKey() + ": " + entry.getValue())
            .collect(Collectors.joining(", "));
        
        ApiResponse<?> response = ApiResponse.<Map<String, String>>error(
            "Dữ liệu không hợp lệ: " + errorMessage,
            HttpStatus.BAD_REQUEST.value(),
            "VALIDATION_ERROR"
        ).builder()
            .data(errors)
            .build();
        
        return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
    }
    
    // ==================== Security Exceptions ====================
    
    @ExceptionHandler(org.springframework.security.access.AccessDeniedException.class)
    public ResponseEntity<ApiResponse<?>> handleAccessDeniedException(
            org.springframework.security.access.AccessDeniedException ex) {
        ApiResponse<?> response = ApiResponse.error(
            "Bạn không có quyền thực hiện thao tác này",
            HttpStatus.FORBIDDEN.value(),
            "PERMISSION_DENIED"
        );
        return new ResponseEntity<>(response, HttpStatus.FORBIDDEN);
    }
    
    @ExceptionHandler(org.springframework.security.core.AuthenticationException.class)
    public ResponseEntity<ApiResponse<?>> handleAuthenticationException(
            org.springframework.security.core.AuthenticationException ex) {
        ApiResponse<?> response = ApiResponse.error(
            "Xác thực thất bại. Vui lòng đăng nhập lại.",
            HttpStatus.UNAUTHORIZED.value(),
            "AUTHENTICATION_FAILED"
        );
        return new ResponseEntity<>(response, HttpStatus.UNAUTHORIZED);
    }
    
    // ==================== File Upload Exceptions ====================
    
    @ExceptionHandler(org.springframework.web.multipart.MaxUploadSizeExceededException.class)
    public ResponseEntity<ApiResponse<?>> handleMaxUploadSizeExceededException(
            org.springframework.web.multipart.MaxUploadSizeExceededException ex) {
        ApiResponse<?> response = ApiResponse.error(
            "File quá lớn. Kích thước tối đa cho phép là 10MB.",
            HttpStatus.PAYLOAD_TOO_LARGE.value(),
            "FILE_TOO_LARGE"
        );
        return new ResponseEntity<>(response, HttpStatus.PAYLOAD_TOO_LARGE);
    }
    
    // ==================== Generic Exception Handler ====================
    
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<?>> handleGlobalException(Exception ex) {
        log.error("Unhandled exception while processing request", ex);
        
        ApiResponse<?> response = ApiResponse.error(
            "Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.",
            HttpStatus.INTERNAL_SERVER_ERROR.value(),
            "SERVER_ERROR"
        );
        return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
    }
}
