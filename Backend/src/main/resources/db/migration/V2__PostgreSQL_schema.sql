-- ============================================
-- PostgreSQL Schema for Tram Doc API
-- Run this only if using PostgreSQL
-- ============================================

-- NOTE: With ddl-auto=update, Hibernate will create tables automatically
-- This file is for reference and manual setup if needed

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(500),
    bio TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Books table
CREATE TABLE IF NOT EXISTS books (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    author VARCHAR(255),
    isbn VARCHAR(20) UNIQUE,
    cover_image_url VARCHAR(500),
    description TEXT,
    publisher VARCHAR(255),
    published_date DATE,
    page_count INTEGER,
    language VARCHAR(50) DEFAULT 'vi',
    category VARCHAR(100),
    google_books_id VARCHAR(50) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User Books table
CREATE TABLE IF NOT EXISTS user_books (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id BIGINT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'WANT_TO_READ',
    current_page INTEGER DEFAULT 0,
    total_pages INTEGER,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    location VARCHAR(255),
    started_at DATE,
    completed_at DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, book_id)
);

-- Reading Progress table
CREATE TABLE IF NOT EXISTS reading_progress (
    id BIGSERIAL PRIMARY KEY,
    user_book_id BIGINT NOT NULL REFERENCES user_books(id) ON DELETE CASCADE,
    page_number INTEGER NOT NULL,
    reading_date DATE NOT NULL,
    notes TEXT,
    reading_duration_minutes INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notes table
CREATE TABLE IF NOT EXISTS notes (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id BIGINT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    title VARCHAR(255),
    content TEXT NOT NULL,
    page_number INTEGER,
    tags VARCHAR(500),
    is_flashcard BOOLEAN DEFAULT FALSE,
    ocr_image_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Flashcards table
CREATE TABLE IF NOT EXISTS flashcards (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id BIGINT REFERENCES books(id) ON DELETE SET NULL,
    note_id BIGINT REFERENCES notes(id) ON DELETE SET NULL,
    deck_name VARCHAR(255) DEFAULT 'Default',
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    interval_days INTEGER DEFAULT 1,
    ease_factor DOUBLE PRECISION DEFAULT 2.50,
    repetitions INTEGER DEFAULT 0,
    next_review_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Flashcard Reviews table
CREATE TABLE IF NOT EXISTS flashcard_reviews (
    id BIGSERIAL PRIMARY KEY,
    flashcard_id BIGINT NOT NULL REFERENCES flashcards(id) ON DELETE CASCADE,
    review_date TIMESTAMP NOT NULL,
    quality INTEGER NOT NULL CHECK (quality >= 0 AND quality <= 5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Key Takeaways table
CREATE TABLE IF NOT EXISTS key_takeaways (
    id BIGSERIAL PRIMARY KEY,
    user_book_id BIGINT NOT NULL REFERENCES user_books(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    page_number INTEGER,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Friends table
CREATE TABLE IF NOT EXISTS friends (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    friend_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, friend_id)
);

-- Activities table
CREATE TABLE IF NOT EXISTS activities (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_type VARCHAR(50) NOT NULL,
    book_id BIGINT REFERENCES books(id) ON DELETE SET NULL,
    metadata TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Activity Likes table
CREATE TABLE IF NOT EXISTS activity_likes (
    id BIGSERIAL PRIMARY KEY,
    activity_id BIGINT NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(activity_id, user_id)
);

-- Activity Comments table
CREATE TABLE IF NOT EXISTS activity_comments (
    id BIGSERIAL PRIMARY KEY,
    activity_id BIGINT NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notification Settings table
CREATE TABLE IF NOT EXISTS notification_settings (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    enabled BOOLEAN DEFAULT TRUE,
    reminder_time TIME DEFAULT '20:00:00',
    reminder_days VARCHAR(50) DEFAULT '1,2,3,4,5',
    sound_enabled BOOLEAN DEFAULT TRUE,
    vibration_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_books_user_id ON user_books(user_id);
CREATE INDEX IF NOT EXISTS idx_user_books_status ON user_books(status);
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_flashcards_user_id ON flashcards(user_id);
CREATE INDEX IF NOT EXISTS idx_flashcards_next_review ON flashcards(next_review_date);
CREATE INDEX IF NOT EXISTS idx_activities_user_id ON activities(user_id);
CREATE INDEX IF NOT EXISTS idx_friends_user_id ON friends(user_id);
