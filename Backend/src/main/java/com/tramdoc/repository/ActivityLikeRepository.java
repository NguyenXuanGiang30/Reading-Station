package com.tramdoc.repository;

import com.tramdoc.entity.ActivityLike;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ActivityLikeRepository extends JpaRepository<ActivityLike, Long> {
    Optional<ActivityLike> findByActivityIdAndUserId(Long activityId, Long userId);
    long countByActivityId(Long activityId);
}
