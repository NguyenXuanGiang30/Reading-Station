/// Form Validation Helpers - Reusable validators for forms
library;

import 'package:flutter/material.dart';

/// Result of a validation check
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  
  const ValidationResult.valid()
      : isValid = true,
        errorMessage = null;
  
  const ValidationResult.invalid(this.errorMessage)
      : isValid = false;
  
  factory ValidationResult.success() => const ValidationResult.valid();
  factory ValidationResult.failure(String message) => ValidationResult.invalid(message);
}

/// Common validators for forms
class Validators {
  Validators._();
  
  /// Validate required field
  static ValidationResult required(String? value, {String fieldName = 'Trường này'}) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.failure('$fieldName là bắt buộc');
    }
    return ValidationResult.success();
  }
  
  /// Validate email
  static ValidationResult email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.failure('Email là bắt buộc');
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return ValidationResult.failure('Email không hợp lệ');
    }
    return ValidationResult.success();
  }
  
  /// Validate password
  static ValidationResult password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return ValidationResult.failure('Mật khẩu là bắt buộc');
    }
    
    if (value.length < minLength) {
      return ValidationResult.failure('Mật khẩu phải có ít nhất $minLength ký tự');
    }
    
    // Check for at least one letter and one number
    final hasLetter = value.contains(RegExp(r'[a-zA-Z]'));
    final hasNumber = value.contains(RegExp(r'[0-9]'));
    
    if (!hasLetter || !hasNumber) {
      return ValidationResult.failure('Mật khẩu phải chứa cả chữ và số');
    }
    
    return ValidationResult.success();
  }
  
  /// Validate password strength
  static ValidationResult strongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationResult.failure('Mật khẩu là bắt buộc');
    }
    
    if (value.length < 8) {
      return ValidationResult.failure('Mật khẩu phải có ít nhất 8 ký tự');
    }
    
    final errors = <String>[];
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      errors.add('chữ thường');
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      errors.add('chữ hoa');
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      errors.add('số');
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('ký tự đặc biệt');
    }
    
    if (errors.isNotEmpty) {
      return ValidationResult.failure(
        'Mật khẩu phải chứa: ${errors.join(", ")}',
      );
    }
    
    return ValidationResult.success();
  }
  
  /// Validate confirm password
  static ValidationResult confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return ValidationResult.failure('Vui lòng nhập lại mật khẩu');
    }
    
    if (value != password) {
      return ValidationResult.failure('Mật khẩu không khớp');
    }
    
    return ValidationResult.success();
  }
  
  /// Validate minimum length
  static ValidationResult minLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return ValidationResult.failure('${fieldName ?? "Giá trị"} là bắt buộc');
    }
    
    if (value.length < minLength) {
      return ValidationResult.failure(
        '${fieldName ?? "Giá trị"} phải có ít nhất $minLength ký tự',
      );
    }
    
    return ValidationResult.success();
  }
  
  /// Validate maximum length
  static ValidationResult maxLength(String? value, int maxLength, {String? fieldName}) {
    if (value != null && value.length > maxLength) {
      return ValidationResult.failure(
        '${fieldName ?? "Giá trị"} không được vượt quá $maxLength ký tự',
      );
    }
    
    return ValidationResult.success();
  }
  
  /// Validate phone number (Vietnamese format)
  static ValidationResult phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.failure('Số điện thoại là bắt buộc');
    }
    
    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    // Vietnamese phone numbers: 10 digits starting with 0, +84, or 84
    final phoneRegex = RegExp(r'^(0|84|\+84)?[3-9]\d{8}$');
    
    if (!phoneRegex.hasMatch(digitsOnly)) {
      return ValidationResult.failure('Số điện thoại không hợp lệ');
    }
    
    return ValidationResult.success();
  }
  
  /// Validate URL
  static ValidationResult url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.success(); // URL is optional
    }
    
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    
    if (!urlRegex.hasMatch(value.trim())) {
      return ValidationResult.failure('URL không hợp lệ');
    }
    
    return ValidationResult.success();
  }
  
  /// Validate ISBN
  static ValidationResult isbn(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.success(); // ISBN is optional
    }
    
    // Remove dashes and spaces
    final cleanIsbn = value.replaceAll(RegExp(r'[-\s]'), '');
    
    // ISBN-10 or ISBN-13
    if (cleanIsbn.length == 10) {
      return ValidationResult.success();
    } else if (cleanIsbn.length == 13) {
      return ValidationResult.success();
    }
    
    return ValidationResult.failure('ISBN không hợp lệ');
  }
  
  /// Validate OTP code (6 digits)
  static ValidationResult otp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.failure('Mã OTP là bắt buộc');
    }
    
    final otpRegex = RegExp(r'^\d{6}$');
    
    if (!otpRegex.hasMatch(value.trim())) {
      return ValidationResult.failure('Mã OTP phải gồm 6 chữ số');
    }
    
    return ValidationResult.success();
  }
  
  /// Combine multiple validators
  static ValidationResult combine(List<ValidationResult> results) {
    for (final result in results) {
      if (!result.isValid) {
        return result;
      }
    }
    return ValidationResult.success();
  }
}

/// Form field state for reactive validation
class FormFieldState {
  final String value;
  final String? errorText;
  final bool isValid;
  final bool isDirty;
  final bool isFocused;
  
  const FormFieldState({
    this.value = '',
    this.errorText,
    this.isValid = false,
    this.isDirty = false,
    this.isFocused = false,
  });
  
  FormFieldState copyWith({
    String? value,
    String? errorText,
    bool? isValid,
    bool? isDirty,
    bool? isFocused,
  }) {
    return FormFieldState(
      value: value ?? this.value,
      errorText: errorText,
      isValid: isValid ?? this.isValid,
      isDirty: isDirty ?? this.isDirty,
      isFocused: isFocused ?? this.isFocused,
    );
  }
}

/// Mixin for forms with validation
mixin FormValidationMixin<T extends StatefulWidget> on State<T> {
  final Map<String, FormFieldState> _fields = {};
  
  Map<String, FormFieldState> get fields => Map.unmodifiable(_fields);
  
  void initField(String name, {String initialValue = ''}) {
    _fields[name] = FormFieldState(value: initialValue);
  }
  
  void updateField(String name, String value) {
    setState(() {
      _fields[name] = _fields[name]?.copyWith(value: value) 
          ?? FormFieldState(value: value);
    });
  }
  
  void validateField(String name, ValidationResult result) {
    setState(() {
      _fields[name] = _fields[name]?.copyWith(
        isValid: result.isValid,
        errorText: result.errorMessage,
        isDirty: true,
      ) ?? FormFieldState(
        value: '',
        isValid: result.isValid,
        errorText: result.errorMessage,
        isDirty: true,
      );
    });
  }
  
  void setFieldFocused(String name, bool focused) {
    setState(() {
      _fields[name] = _fields[name]?.copyWith(isFocused: focused) ?? FormFieldState(isFocused: focused);
    });
  }
  
  bool validateAll(Map<String, ValidationResult Function(String?)> validators) {
    bool allValid = true;
    
    for (final entry in validators.entries) {
      final field = _fields[entry.key];
      if (field == null) continue;
      
      final result = entry.value(field.value);
      validateField(entry.key, result);
      
      if (!result.isValid) {
        allValid = false;
      }
    }
    
    return allValid;
  }
  
  void clearField(String name) {
    setState(() {
      _fields[name] = FormFieldState(value: '');
    });
  }
  
  void clearAllFields() {
    setState(() {
      for (final key in _fields.keys) {
        _fields[key] = FormFieldState(value: '');
      }
    });
  }
}
