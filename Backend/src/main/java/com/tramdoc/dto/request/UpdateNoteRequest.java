package com.tramdoc.dto.request;

import lombok.Data;

@Data
public class UpdateNoteRequest {
    private String title;
    private String content;
    private Integer pageNumber;
    private String tags;
}
