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
@Table(name = "user_books", 
       uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "book_id"}))
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class UserBook {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "book_id", nullable = false)
    private Book book;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private BookStatus status = BookStatus.WANT_TO_READ;
    
    @Column(name = "current_page")
    @Builder.Default
    private Integer currentPage = 0;
    
    @Column(name = "total_pages")
    private Integer totalPages;
    
    @Column(name = "rating")
    private Integer rating; // 1-5
    
    @Column(columnDefinition = "TEXT")
    private String review;
    
    @Column(length = 255)
    private String location; // Vị trí sách giấy
    
    @Column(name = "started_at")
    private LocalDate startedAt;
    
    @Column(name = "completed_at")
    private LocalDate completedAt;
    
    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    
    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    public enum BookStatus {
        WANT_TO_READ,
        READING,
        READ
    }
}
