package com.tramdoc.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class CommentResponse {
    private Long id;
    private Long activityId;
    private Long userId;
    private String userName;
    private String userAvatarUrl;
    private String content;
    private LocalDateTime createdAt;
}
