package com.tramdoc.dto.request;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.tramdoc.entity.UserBook.BookStatus;
import lombok.Data;

@Data
public class UpdateUserBookRequest {
    private String title;
    private String author;
    private String isbn;

    @JsonAlias("coverImageUrl")
    private String coverUrl;

    private String description;
    private String category;
    private String publisher;
    private Integer publishYear;
    private BookStatus status;
    private Integer currentPage;

    @JsonAlias("pageCount")
    private Integer totalPages;

    private Integer rating;
    private String review;
    private String location;
}
