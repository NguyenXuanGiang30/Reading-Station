package com.tramdoc.repository;

import com.tramdoc.entity.Activity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ActivityRepository extends JpaRepository<Activity, Long> {
    Page<Activity> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);
    
    @Query("SELECT a FROM Activity a WHERE a.user.id IN :friendIds ORDER BY a.createdAt DESC")
    Page<Activity> findActivitiesByFriendIds(@Param("friendIds") List<Long> friendIds, Pageable pageable);
}
