-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(500),
    bio TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create books table
CREATE TABLE IF NOT EXISTS books (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(500) NOT NULL,
    author VARCHAR(255),
    isbn VARCHAR(20) UNIQUE,
    cover_image_url VARCHAR(500),
    description TEXT,
    publisher VARCHAR(255),
    published_date DATE,
    page_count INT,
    language VARCHAR(50) DEFAULT 'vi',
    category VARCHAR(100),
    google_books_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_title (title),
    INDEX idx_author (author),
    INDEX idx_isbn (isbn)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create user_books table
CREATE TABLE IF NOT EXISTS user_books (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    book_id BIGINT NOT NULL,
    status ENUM('WANT_TO_READ', 'READING', 'READ') DEFAULT 'WANT_TO_READ',
    current_page INT DEFAULT 0,
    total_pages INT,
    rating INT CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    location VARCHAR(255),
    started_at DATE,
    completed_at DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_book (user_id, book_id),
    INDEX idx_user_status (user_id, status),
    INDEX idx_user_reading (user_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create reading_progress table
CREATE TABLE IF NOT EXISTS reading_progress (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_book_id BIGINT NOT NULL,
    page_number INT NOT NULL,
    notes TEXT,
    reading_date DATE NOT NULL,
    reading_duration_minutes INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_book_id) REFERENCES user_books(id) ON DELETE CASCADE,
    INDEX idx_user_book_date (user_book_id, reading_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create notes table
CREATE TABLE IF NOT EXISTS notes (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    book_id BIGINT NOT NULL,
    title VARCHAR(255),
    content TEXT NOT NULL,
    page_number INT,
    tags VARCHAR(500),
    is_flashcard BOOLEAN DEFAULT FALSE,
    ocr_image_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
    INDEX idx_user_book (user_id, book_id),
    INDEX idx_user_created (user_id, created_at),
    FULLTEXT idx_content (content)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create flashcards table
CREATE TABLE IF NOT EXISTS flashcards (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    book_id BIGINT NOT NULL,
    note_id BIGINT,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    deck_name VARCHAR(255) DEFAULT 'default',
    ease_factor DOUBLE DEFAULT 2.50,
    interval_days INT DEFAULT 1,
    repetitions INT DEFAULT 0,
    next_review_date DATE NOT NULL,
    last_review_date DATE,
    total_reviews INT DEFAULT 0,
    correct_count INT DEFAULT 0,
    incorrect_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
    FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE SET NULL,
    INDEX idx_user_next_review (user_id, next_review_date),
    INDEX idx_user_book (user_id, book_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create flashcard_reviews table
CREATE TABLE IF NOT EXISTS flashcard_reviews (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    flashcard_id BIGINT NOT NULL,
    review_result ENUM('FORGOT', 'REMEMBERED', 'MASTERED') NOT NULL,
    review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    time_spent_seconds INT,
    FOREIGN KEY (flashcard_id) REFERENCES flashcards(id) ON DELETE CASCADE,
    INDEX idx_flashcard_date (flashcard_id, review_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create key_takeaways table
CREATE TABLE IF NOT EXISTS key_takeaways (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_book_id BIGINT NOT NULL,
    content TEXT NOT NULL,
    page_number INT,
    order_index INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_book_id) REFERENCES user_books(id) ON DELETE CASCADE,
    INDEX idx_user_book (user_book_id, order_index)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create friends table
CREATE TABLE IF NOT EXISTS friends (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    friend_id BIGINT NOT NULL,
    status ENUM('PENDING', 'ACCEPTED', 'BLOCKED') DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (friend_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_friendship (user_id, friend_id),
    INDEX idx_user_status (user_id, status),
    INDEX idx_friend_status (friend_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create activities table
CREATE TABLE IF NOT EXISTS activities (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    activity_type ENUM('BOOK_ADDED', 'BOOK_STATUS_CHANGED', 'BOOK_COMPLETED', 'NOTE_CREATED', 'REVIEW_POSTED', 'PROGRESS_UPDATED') NOT NULL,
    book_id BIGINT,
    user_book_id BIGINT,
    note_id BIGINT,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE SET NULL,
    FOREIGN KEY (user_book_id) REFERENCES user_books(id) ON DELETE SET NULL,
    INDEX idx_user_created (user_id, created_at),
    INDEX idx_friends_feed (user_id, activity_type, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create activity_likes table
CREATE TABLE IF NOT EXISTS activity_likes (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    activity_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (activity_id) REFERENCES activities(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_activity_like (activity_id, user_id),
    INDEX idx_activity (activity_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create activity_comments table
CREATE TABLE IF NOT EXISTS activity_comments (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    activity_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (activity_id) REFERENCES activities(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_activity (activity_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create notification_settings table
CREATE TABLE IF NOT EXISTS notification_settings (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL UNIQUE,
    enabled BOOLEAN DEFAULT TRUE,
    reminder_time TIME DEFAULT '20:00:00',
    reminder_days VARCHAR(20) DEFAULT '1,2,3,4,5',
    sound_enabled BOOLEAN DEFAULT TRUE,
    vibration_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
