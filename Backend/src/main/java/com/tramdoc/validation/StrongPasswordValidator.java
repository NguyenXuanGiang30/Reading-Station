package com.tramdoc.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

public class StrongPasswordValidator implements ConstraintValidator<StrongPassword, String> {

    // Special characters allowed
    private static final String SPECIAL_CHARS = "!@#$%^&*()_+-=[]{}|;':\",./<>?~`";

    @Override
    public void initialize(StrongPassword constraintAnnotation) {
        // No initialization needed
    }

    @Override
    public boolean isValid(String password, ConstraintValidatorContext context) {
        if (password == null || password.isEmpty()) {
            return true; // Let @NotBlank handle null/empty
        }

        // Disable default message
        context.disableDefaultConstraintViolation();

        // Check minimum length (6 characters)
        if (password.length() < 6) {
            context.buildConstraintViolationWithTemplate("Mật khẩu phải có ít nhất 6 ký tự")
                    .addConstraintViolation();
            return false;
        }

        // Check first character is uppercase
        if (!Character.isUpperCase(password.charAt(0))) {
            context.buildConstraintViolationWithTemplate("Chữ cái đầu tiên phải viết hoa")
                    .addConstraintViolation();
            return false;
        }

        // Check contains at least one digit
        boolean hasDigit = false;
        for (char c : password.toCharArray()) {
            if (Character.isDigit(c)) {
                hasDigit = true;
                break;
            }
        }
        if (!hasDigit) {
            context.buildConstraintViolationWithTemplate("Mật khẩu phải chứa ít nhất một chữ số")
                    .addConstraintViolation();
            return false;
        }

        // Check contains at least one special character
        boolean hasSpecial = false;
        for (char c : password.toCharArray()) {
            if (SPECIAL_CHARS.indexOf(c) >= 0) {
                hasSpecial = true;
                break;
            }
        }
        if (!hasSpecial) {
            context.buildConstraintViolationWithTemplate("Mật khẩu phải chứa ít nhất một ký tự đặc biệt (!@#$%^&*...)")
                    .addConstraintViolation();
            return false;
        }

        return true;
    }
}
