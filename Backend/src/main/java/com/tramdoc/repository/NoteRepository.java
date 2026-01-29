package com.tramdoc.repository;

import com.tramdoc.entity.Note;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NoteRepository extends JpaRepository<Note, Long> {
    Page<Note> findByUser_Id(Long userId, Pageable pageable);
    Page<Note> findByUser_IdAndBook_Id(Long userId, Long bookId, Pageable pageable);
    List<Note> findByBook_IdOrderByPageNumberAsc(Long bookId);
    
    @Query("SELECT n FROM Note n WHERE n.user.id = :userId AND " +
           "(LOWER(n.title) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(n.content) LIKE LOWER(CONCAT('%', :query, '%')))")
    Page<Note> searchNotes(@Param("userId") Long userId, @Param("query") String query, Pageable pageable);
}
