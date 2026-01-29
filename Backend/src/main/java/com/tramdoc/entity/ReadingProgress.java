package com.tramdoc.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "reading_progress")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class ReadingProgress {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_book_id", nullable = false)
    private UserBook userBook;
    
    @Column(name = "page_number", nullable = false)
    private Integer pageNumber;
    
    @Column(columnDefinition = "TEXT")
    private String notes;
    
    @Column(name = "reading_date", nullable = false)
    private LocalDate readingDate;
    
    @Column(name = "reading_duration_minutes")
    private Integer readingDurationMinutes;
    
    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
