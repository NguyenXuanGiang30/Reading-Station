package com.tramdoc.repository;

import com.tramdoc.entity.Friend;
import com.tramdoc.entity.Friend.FriendStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FriendRepository extends JpaRepository<Friend, Long> {
    Optional<Friend> findByUserIdAndFriendId(Long userId, Long friendId);
    Page<Friend> findByUserIdAndStatus(Long userId, FriendStatus status, Pageable pageable);
    Page<Friend> findByFriendIdAndStatus(Long friendId, FriendStatus status, Pageable pageable);
    
    @Query("SELECT f FROM Friend f WHERE (f.user.id = :userId OR f.friend.id = :userId) AND f.status = 'ACCEPTED'")
    List<Friend> findAcceptedFriends(@Param("userId") Long userId);
}
