package com.tramdoc.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BookResponse {
    private Long id;
    private String title;
    private String author;
    private String isbn;
    private String coverImageUrl;
    private String description;
    private String publisher;
    private LocalDate publishedDate;
    private Integer pageCount;
    private String language;
    private String category;
    private String googleBooksId;
}
