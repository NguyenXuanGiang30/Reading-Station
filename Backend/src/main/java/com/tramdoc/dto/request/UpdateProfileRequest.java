package com.tramdoc.dto.request;

import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UpdateProfileRequest {
    
    @Size(min = 2, max = 255, message = "Họ tên phải từ 2 đến 255 ký tự")
    private String fullName;
    
    @Size(max = 500, message = "Bio không được quá 500 ký tự")
    private String bio;
    
    @Size(max = 500, message = "URL ảnh đại diện không được quá 500 ký tự")
    private String avatarUrl;
}
