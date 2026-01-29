package com.tramdoc.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDate;

@Data
public class CreateBookRequest {
    
    @NotBlank(message = "Tiêu đề sách không được để trống")
    @Size(max = 500, message = "Tiêu đề không được quá 500 ký tự")
    private String title;
    
    @Size(max = 255, message = "Tên tác giả không được quá 255 ký tự")
    private String author;
    
    @Size(max = 20, message = "ISBN không được quá 20 ký tự")
    private String isbn;
    
    @Size(max = 500, message = "URL ảnh bìa không được quá 500 ký tự")
    private String coverImageUrl;
    
    private String description;
    
    @Size(max = 255, message = "Nhà xuất bản không được quá 255 ký tự")
    private String publisher;
    
    private LocalDate publishedDate;
    
    private Integer pageCount;
    
    @Size(max = 50, message = "Ngôn ngữ không được quá 50 ký tự")
    private String language;
    
    @Size(max = 100, message = "Thể loại không được quá 100 ký tự")
    private String category;
}
