package com.tramdoc.dto.response;

import com.tramdoc.entity.Activity.ActivityType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ActivityResponse {
    private Long id;
    private Long userId;
    private String userName;
    private String userAvatarUrl;
    private ActivityType activityType;
    private Long bookId;
    private String bookTitle;
    private String bookCoverUrl;
    private String metadata;
    private Long likeCount;
    private Long commentCount;
    private LocalDateTime createdAt;
}
