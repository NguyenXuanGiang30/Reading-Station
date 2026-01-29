package com.tramdoc.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CreateCommentRequest {
    
    @NotBlank(message = "Nội dung comment không được để trống")
    @Size(max = 1000, message = "Comment không được quá 1000 ký tự")
    private String content;
}
