package com.tramdoc.repository;

import com.tramdoc.entity.Flashcard;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface FlashcardRepository extends JpaRepository<Flashcard, Long> {
    Page<Flashcard> findByUser_Id(Long userId, Pageable pageable);
    Page<Flashcard> findByUser_IdAndBook_Id(Long userId, Long bookId, Pageable pageable);
    List<Flashcard> findByUser_IdAndNextReviewDateLessThanEqual(Long userId, LocalDate date);
    
    @Query("SELECT f FROM Flashcard f WHERE f.user.id = :userId AND f.nextReviewDate <= :date ORDER BY f.nextReviewDate ASC")
    List<Flashcard> findDueCards(@Param("userId") Long userId, @Param("date") LocalDate date);
    
    @Query("SELECT DISTINCT f.deckName FROM Flashcard f WHERE f.user.id = :userId")
    List<String> findDistinctDeckNamesByUserId(@Param("userId") Long userId);
    
    @Query("SELECT COUNT(f) FROM Flashcard f WHERE f.user.id = :userId AND f.nextReviewDate <= :date")
    Long countDueCards(@Param("userId") Long userId, @Param("date") LocalDate date);
}
