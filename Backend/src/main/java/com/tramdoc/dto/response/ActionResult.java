package com.tramdoc.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ActionResult {
    private String tool;           // e.g. "search_book_isbn"
    private boolean success;
    private String message;        // Human-readable summary
    private Map<String, Object> data; // Tool-specific payload (book info, stats, etc.)
}
