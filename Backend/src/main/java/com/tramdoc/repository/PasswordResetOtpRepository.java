package com.tramdoc.repository;

import com.tramdoc.entity.PasswordResetOtp;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface PasswordResetOtpRepository extends JpaRepository<PasswordResetOtp, Long> {

    Optional<PasswordResetOtp> findByUserIdAndOtpAndUsedFalse(Long userId, String otp);

    Optional<PasswordResetOtp> findFirstByUserIdAndUsedFalseOrderByCreatedAtDesc(Long userId);

    @Modifying
    @Query("UPDATE PasswordResetOtp o SET o.used = true WHERE o.user.id = :userId")
    void markAllAsUsedByUserId(Long userId);

    @Modifying
    @Query("DELETE FROM PasswordResetOtp o WHERE o.expiresAt < :now")
    void deleteExpiredOtps(LocalDateTime now);
}
