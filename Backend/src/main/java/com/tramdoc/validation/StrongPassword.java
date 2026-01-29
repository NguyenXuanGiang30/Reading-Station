package com.tramdoc.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;
import java.lang.annotation.*;

@Documented
@Constraint(validatedBy = StrongPasswordValidator.class)
@Target({ ElementType.FIELD, ElementType.PARAMETER })
@Retention(RetentionPolicy.RUNTIME)
public @interface StrongPassword {
    String message() default "Mật khẩu phải có chữ cái đầu viết hoa, chứa số và ký tự đặc biệt, tối thiểu 6 ký tự";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
