package com.tramdoc.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;
import java.lang.annotation.*;

@Documented
@Constraint(validatedBy = ValidEmailDomainValidator.class)
@Target({ ElementType.FIELD, ElementType.PARAMETER })
@Retention(RetentionPolicy.RUNTIME)
public @interface ValidEmailDomain {
    String message() default "Email phải sử dụng các nhà cung cấp phổ biến (Gmail, Yahoo, Outlook, v.v.)";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
