-- ============================================
-- V3: Add OAuth fields and Password Reset OTP
-- ============================================

-- 1. Add OAuth fields to users table
ALTER TABLE users ADD COLUMN auth_provider VARCHAR(20) DEFAULT 'LOCAL';
ALTER TABLE users ADD COLUMN provider_id VARCHAR(255);
ALTER TABLE users MODIFY COLUMN password VARCHAR(255) NULL;

-- 2. Create password_reset_otps table
CREATE TABLE IF NOT EXISTS password_reset_otps (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    otp VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_otp (user_id, otp),
    INDEX idx_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Add user_settings table (also missing from V1)
CREATE TABLE IF NOT EXISTS user_settings (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL UNIQUE,
    theme VARCHAR(20) DEFAULT 'SYSTEM',
    language VARCHAR(10) DEFAULT 'vi',
    daily_reading_goal INT DEFAULT 30,
    reading_reminder_enabled BOOLEAN DEFAULT TRUE,
    reading_reminder_time TIME DEFAULT '20:00:00',
    flashcard_new_cards_per_day INT DEFAULT 20,
    flashcard_review_limit INT DEFAULT 100,
    auto_convert_notes BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
