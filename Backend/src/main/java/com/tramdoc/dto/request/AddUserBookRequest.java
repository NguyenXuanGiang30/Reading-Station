package com.tramdoc.dto.request;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.tramdoc.entity.UserBook.BookStatus;
import lombok.Data;

@Data
public class AddUserBookRequest {
    private Long bookId;
    private String isbn;
    private String title;
    private String author;

    @JsonAlias("coverImageUrl")
    private String coverUrl;

    @JsonAlias("pageCount")
    private Integer totalPages;

    private String description;
    private String category;
    private String publisher;
    private Integer publishYear;
    private BookStatus status = BookStatus.WANT_TO_READ;
    private String location;
}
