package com.tramdoc.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;
import org.springframework.stereotype.Component;

import java.util.regex.Pattern;

@Component
public class InputSanitizerValidator implements ConstraintValidator<InputSanitizer, String> {
    
    // Patterns for different sanitization types
    private static final Pattern HTML_PATTERN = Pattern.compile(
        "<[^>]*>",
        Pattern.CASE_INSENSITIVE
    );
    
    private static final Pattern SCRIPT_PATTERN = Pattern.compile(
        "<script[^>]*>.*?</script>|<[^>]+javascript:|<[^>]+on\\w+\\s*=",
        Pattern.CASE_INSENSITIVE | Pattern.DOTALL
    );
    
    private static final Pattern SQL_INJECTION_PATTERN = Pattern.compile(
        "(\\b(SELECT|INSERT|UPDATE|DELETE|DROP|UNION|ALTER|CREATE|TRUNCATE)\\b)|(--)|(;)|(/\\*)|(\\*/)",
        Pattern.CASE_INSENSITIVE
    );
    
    private static final Pattern EMAIL_PATTERN = Pattern.compile(
        "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
    );
    
    private static final Pattern URL_PATTERN = Pattern.compile(
        "^(https?|ftp)://[^\\s/$.?#].[^\\s]*$",
        Pattern.CASE_INSENSITIVE
    );
    
    private static final Pattern USERNAME_PATTERN = Pattern.compile(
        "^[a-zA-Z0-9_]{3,20}$"
    );
    
    private SanitizationType type;
    
    @Override
    public void initialize(InputSanitizer constraintAnnotation) {
        this.type = constraintAnnotation.type();
    }
    
    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        if (value == null || value.isEmpty()) {
            return true; // Let @NotNull handle empty values
        }
        
        switch (type) {
            case TEXT:
                return sanitizeText(value);
            case HTML:
                return sanitizeHtml(value);
            case EMAIL:
                return sanitizeEmail(value);
            case URL:
                return sanitizeUrl(value);
            case USERNAME:
                return sanitizeUsername(value);
            case PASSWORD:
                return sanitizePassword(value);
            default:
                return sanitizeText(value);
        }
    }
    
    private boolean sanitizeText(String value) {
        // Remove potential XSS vectors
        if (SCRIPT_PATTERN.matcher(value).find()) {
            return false;
        }
        
        // Check for SQL injection patterns
        if (SQL_INJECTION_PATTERN.matcher(value).find()) {
            return false;
        }
        
        return true;
    }
    
    private boolean sanitizeHtml(String value) {
        // Remove HTML tags for plain text storage
        return true; // HTML sanitization should be done on output, not input
    }
    
    private boolean sanitizeEmail(String value) {
        return EMAIL_PATTERN.matcher(value.trim()).matches();
    }
    
    private boolean sanitizeUrl(String value) {
        return URL_PATTERN.matcher(value.trim()).matches();
    }
    
    private boolean sanitizeUsername(String value) {
        return USERNAME_PATTERN.matcher(value).matches();
    }
    
    private boolean sanitizePassword(String value) {
        // Password should not contain obvious patterns
        if (value.length() < 6 || value.length() > 128) {
            return false;
        }
        
        // Check for common weak passwords
        String lower = value.toLowerCase();
        if (lower.contains("password") || lower.contains("123456")) {
            return false;
        }
        
        return true;
    }
    
    // Static sanitization methods for manual use
    public static String sanitizeForDisplay(String value) {
        if (value == null) return null;
        
        // Escape HTML characters
        return value
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&#x27;")
            .replace("/", "&#x2F;");
    }
    
    public static String stripHtml(String value) {
        if (value == null) return null;
        return HTML_PATTERN.matcher(value).replaceAll("");
    }
}
