package com.tramdoc.dto.request;

import com.tramdoc.entity.UserBook.BookStatus;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class AddUserBookRequest {
    @NotNull(message = "Book ID không được để trống")
    private Long bookId;
    
    private BookStatus status = BookStatus.WANT_TO_READ;
    
    private String location; // Vị trí sách giấy
}
