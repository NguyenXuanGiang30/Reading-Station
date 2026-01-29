package com.tramdoc.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

@Data
public class ReorderTakeawaysRequest {
    
    @NotNull(message = "Danh sách ID không được để trống")
    private List<Long> takeawayIds;
}
