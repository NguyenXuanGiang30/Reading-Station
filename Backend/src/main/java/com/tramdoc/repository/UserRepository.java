package com.tramdoc.repository;

import com.tramdoc.entity.AuthProvider;
import com.tramdoc.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);

    Optional<User> findByAuthProviderAndProviderId(AuthProvider authProvider, String providerId);

    @Query("SELECT u FROM User u WHERE (LOWER(u.fullName) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(u.email) LIKE LOWER(CONCAT('%', :query, '%'))) AND u.id != :currentUserId")
    Page<User> searchUsers(@Param("query") String query, @Param("currentUserId") Long currentUserId, Pageable pageable);
}
