package com.tramdoc.dto.request;

import lombok.Data;

@Data
public class UpdateKeyTakeawayRequest {
    private String content;
    private Integer pageNumber;
    private Integer orderIndex;
}
