package com.tramdoc.dto.request;

import com.tramdoc.validation.ValidEmailDomain;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class LoginRequest {

    @NotBlank(message = "Email không được để trống")
    @Email(message = "Email không hợp lệ")
    @ValidEmailDomain
    private String email;

    @NotBlank(message = "Mật khẩu không được để trống")
    private String password;
}
