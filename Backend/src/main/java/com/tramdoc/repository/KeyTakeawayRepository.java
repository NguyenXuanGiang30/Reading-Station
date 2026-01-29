package com.tramdoc.repository;

import com.tramdoc.entity.KeyTakeaway;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface KeyTakeawayRepository extends JpaRepository<KeyTakeaway, Long> {
    List<KeyTakeaway> findByUserBookIdOrderByOrderIndexAsc(Long userBookId);
}
