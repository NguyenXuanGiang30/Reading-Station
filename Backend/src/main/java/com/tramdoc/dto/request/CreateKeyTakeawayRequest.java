package com.tramdoc.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CreateKeyTakeawayRequest {
    @NotBlank(message = "Nội dung không được để trống")
    private String content;
    
    private Integer pageNumber;
    
    private Integer orderIndex;
}
