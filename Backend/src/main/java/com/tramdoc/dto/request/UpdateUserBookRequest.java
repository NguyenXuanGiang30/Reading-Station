package com.tramdoc.dto.request;

import com.tramdoc.entity.UserBook.BookStatus;
import lombok.Data;

@Data
public class UpdateUserBookRequest {
    private BookStatus status;
    private Integer currentPage;
    private Integer totalPages;
    private Integer rating; // 1-5
    private String review;
    private String location;
}
