package com.tramdoc.repository;

import com.tramdoc.entity.FlashcardReview;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FlashcardReviewRepository extends JpaRepository<FlashcardReview, Long> {
    Page<FlashcardReview> findByFlashcardIdOrderByReviewDateDesc(Long flashcardId, Pageable pageable);
}
