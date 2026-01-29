package com.tramdoc.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;
import java.util.Set;

public class ValidEmailDomainValidator implements ConstraintValidator<ValidEmailDomain, String> {

    // Popular email domains
    private static final Set<String> ALLOWED_DOMAINS = Set.of(
            // Google
            "gmail.com",
            "googlemail.com",

            // Microsoft
            "outlook.com",
            "outlook.vn",
            "hotmail.com",
            "hotmail.vn",
            "live.com",
            "msn.com",

            // Yahoo
            "yahoo.com",
            "yahoo.com.vn",
            "yahoo.vn",
            "ymail.com",

            // Apple
            "icloud.com",
            "me.com",
            "mac.com",

            // ProtonMail (privacy-focused)
            "protonmail.com",
            "proton.me",
            "pm.me",

            // Other popular international
            "aol.com",
            "zoho.com",
            "mail.com",
            "gmx.com",
            "gmx.net",
            "yandex.com",
            "yandex.ru",

            // Vietnam popular domains
            "fpt.vn",
            "vnn.vn",
            "hcm.vnn.vn",
            "hn.vnn.vn",
            "viettel.vn",
            "vnpt.vn");

    @Override
    public void initialize(ValidEmailDomain constraintAnnotation) {
        // No initialization needed
    }

    @Override
    public boolean isValid(String email, ConstraintValidatorContext context) {
        if (email == null || email.isBlank()) {
            return true; // Let @NotBlank handle this
        }

        String lowerEmail = email.toLowerCase().trim();

        // Check email format
        if (!lowerEmail.contains("@")) {
            return false;
        }

        // Extract domain
        String domain = lowerEmail.substring(lowerEmail.lastIndexOf("@") + 1);

        // Check if domain is in allowed list
        if (ALLOWED_DOMAINS.contains(domain)) {
            return true;
        }

        // Also allow educational domains (.edu, .edu.vn)
        if (domain.endsWith(".edu") || domain.endsWith(".edu.vn")) {
            return true;
        }

        // Also allow company domains with common TLDs
        if (domain.endsWith(".com.vn") || domain.endsWith(".vn") ||
                domain.endsWith(".com") || domain.endsWith(".org") ||
                domain.endsWith(".net") || domain.endsWith(".io")) {
            // Accept corporate emails but require at least one dot before TLD
            // This allows company@domain.com but not fake@notreal
            int dots = domain.length() - domain.replace(".", "").length();
            return dots >= 1;
        }

        return false;
    }
}
