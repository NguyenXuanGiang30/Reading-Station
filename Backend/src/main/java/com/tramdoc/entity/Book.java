package com.tramdoc.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "books")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class Book {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, length = 500)
    private String title;
    
    @Column(length = 255)
    private String author;
    
    @Column(unique = true, length = 20)
    private String isbn;
    
    @Column(name = "cover_image_url", length = 500)
    private String coverImageUrl;
    
    @Column(columnDefinition = "TEXT")
    private String description;
    
    @Column(length = 255)
    private String publisher;
    
    @Column(name = "published_date")
    private LocalDate publishedDate;
    
    @Column(name = "page_count")
    private Integer pageCount;
    
    @Column(length = 50)
    @Builder.Default
    private String language = "vi";
    
    @Column(length = 100)
    private String category;
    
    @Column(name = "google_books_id", length = 100)
    private String googleBooksId;
    
    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    
    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
