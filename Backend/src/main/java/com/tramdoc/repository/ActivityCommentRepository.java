package com.tramdoc.repository;

import com.tramdoc.entity.ActivityComment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ActivityCommentRepository extends JpaRepository<ActivityComment, Long> {
    Page<ActivityComment> findByActivityIdOrderByCreatedAtAsc(Long activityId, Pageable pageable);
    List<ActivityComment> findByActivityIdOrderByCreatedAtDesc(Long activityId);
    long countByActivityId(Long activityId);
}
