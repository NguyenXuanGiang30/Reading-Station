package com.tramdoc.repository;

import com.tramdoc.entity.UserBook;
import com.tramdoc.entity.UserBook.BookStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserBookRepository extends JpaRepository<UserBook, Long> {
    Page<UserBook> findByUserId(Long userId, Pageable pageable);
    List<UserBook> findByUserId(Long userId);
    Page<UserBook> findByUserIdAndStatus(Long userId, BookStatus status, Pageable pageable);
    Optional<UserBook> findByUserIdAndBookId(Long userId, Long bookId);
    boolean existsByUserIdAndBookId(Long userId, Long bookId);
    List<UserBook> findByBookId(Long bookId);
}
