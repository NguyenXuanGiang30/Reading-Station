package com.tramdoc.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;
import java.lang.annotation.*;

@Target({ElementType.FIELD, ElementType.PARAMETER})
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = InputSanitizerValidator.class)
@Documented
public @interface InputSanitizer {
    String message() default "Input contains potentially dangerous characters";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
    SanitizationType type() default SanitizationType.TEXT;
}
