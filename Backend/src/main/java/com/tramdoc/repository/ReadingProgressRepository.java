package com.tramdoc.repository;

import com.tramdoc.entity.ReadingProgress;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReadingProgressRepository extends JpaRepository<ReadingProgress, Long> {
    Page<ReadingProgress> findByUserBookIdOrderByReadingDateDesc(Long userBookId, Pageable pageable);
    List<ReadingProgress> findByUserBookId(Long userBookId);
}
