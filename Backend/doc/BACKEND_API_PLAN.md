# 🚀 TRẠM ĐỌC - KẾ HOẠCH XÂY DỰNG BACKEND API

> **Spring Boot + MySQL + JWT Authentication**

---

## 📋 MỤC LỤC

1. [Kiến trúc Hệ thống](#kiến-trúc-hệ-thống)
2. [Database Schema](#database-schema)
3. [API Endpoints](#api-endpoints)
4. [Security & JWT](#security--jwt)
5. [Cấu trúc Project](#cấu-trúc-project)
6. [Timeline & Phases](#timeline--phases)
7. [Dependencies](#dependencies)

---

## 🏗️ KIẾN TRÚC HỆ THỐNG

### **Kiến trúc tổng quan:**
```
┌─────────────┐
│   Client    │ (React Web App / Mobile App)
│  (Frontend) │
└──────┬──────┘
       │ HTTPS/REST API
       │
┌──────▼─────────────────────────────────────┐
│         Spring Boot Backend                │
│  ┌─────────────────────────────────────┐  │
│  │  Controllers (REST API Layer)      │  │
│  └──────────────┬──────────────────────┘  │
│                 │                          │
│  ┌──────────────▼──────────────────────┐  │
│  │  Services (Business Logic)         │  │
│  └──────────────┬──────────────────────┘  │
│                 │                          │
│  ┌──────────────▼──────────────────────┐  │
│  │  Repositories (Data Access)         │  │
│  └──────────────┬──────────────────────┘  │
│                 │                          │
│  ┌──────────────▼──────────────────────┐  │
│  │  JWT Security Filter                 │  │
│  └─────────────────────────────────────┘  │
└─────────────────┬──────────────────────────┘
                  │
         ┌────────▼────────┐
         │   MySQL DB      │
         └─────────────────┘
```

### **Layers:**
1. **Controller Layer**: Xử lý HTTP requests/responses
2. **Service Layer**: Business logic, validation
3. **Repository Layer**: Database operations (JPA/Hibernate)
4. **Entity Layer**: Domain models
5. **DTO Layer**: Data Transfer Objects
6. **Security Layer**: JWT authentication & authorization

---

## 🗄️ DATABASE SCHEMA

### **ERD Overview:**
```
User ──┬── UserBook (many-to-many)
       ├── Note
       ├── Flashcard
       ├── ReadingProgress
       ├── KeyTakeaway
       ├── Friend (self-referential)
       └── Activity

Book ──┬── UserBook
       ├── Note
       ├── Flashcard
       └── KeyTakeaway
```

### **Chi tiết các bảng:**

#### **1. users**
```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL, -- BCrypt hashed
    full_name VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(500),
    bio TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_email (email)
);
```

#### **2. books**
```sql
CREATE TABLE books (
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
    google_books_id VARCHAR(100), -- ID từ Google Books API
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_title (title),
    INDEX idx_author (author),
    INDEX idx_isbn (isbn)
);
```

#### **3. user_books** (Quan hệ User-Book với trạng thái)
```sql
CREATE TABLE user_books (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    book_id BIGINT NOT NULL,
    status ENUM('WANT_TO_READ', 'READING', 'READ') DEFAULT 'WANT_TO_READ',
    current_page INT DEFAULT 0,
    total_pages INT,
    rating INT CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    location VARCHAR(255), -- Vị trí sách giấy: "Kệ sách phòng khách"
    started_at DATE,
    completed_at DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_book (user_id, book_id),
    INDEX idx_user_status (user_id, status),
    INDEX idx_user_reading (user_id, status) WHERE status = 'READING'
);
```

#### **4. reading_progress** (Lịch sử cập nhật tiến độ)
```sql
CREATE TABLE reading_progress (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_book_id BIGINT NOT NULL,
    page_number INT NOT NULL,
    notes TEXT, -- Ghi chú về session đọc
    reading_date DATE NOT NULL,
    reading_duration_minutes INT, -- Thời gian đọc (từ Focus Mode)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_book_id) REFERENCES user_books(id) ON DELETE CASCADE,
    INDEX idx_user_book_date (user_book_id, reading_date)
);
```

#### **5. notes**
```sql
CREATE TABLE notes (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    book_id BIGINT NOT NULL,
    title VARCHAR(255),
    content TEXT NOT NULL,
    page_number INT, -- Số trang (optional)
    tags VARCHAR(500), -- Comma-separated tags
    is_flashcard BOOLEAN DEFAULT FALSE, -- Đã chuyển thành flashcard chưa
    ocr_image_url VARCHAR(500), -- URL ảnh OCR (nếu có)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
    INDEX idx_user_book (user_id, book_id),
    INDEX idx_user_created (user_id, created_at),
    FULLTEXT idx_content (content) -- Full-text search
);
```

#### **6. flashcards**
```sql
CREATE TABLE flashcards (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    book_id BIGINT NOT NULL,
    note_id BIGINT, -- NULL nếu tạo thủ công
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    deck_name VARCHAR(255) DEFAULT 'default', -- Tên deck (thường là tên sách)
    
    -- Spaced Repetition (SM-2 Algorithm)
    ease_factor DECIMAL(5,2) DEFAULT 2.50,
    interval_days INT DEFAULT 1,
    repetitions INT DEFAULT 0,
    next_review_date DATE NOT NULL,
    last_review_date DATE,
    
    -- Review stats
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
);
```

#### **7. flashcard_reviews** (Lịch sử review)
```sql
CREATE TABLE flashcard_reviews (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    flashcard_id BIGINT NOT NULL,
    review_result ENUM('FORGOT', 'REMEMBERED', 'MASTERED') NOT NULL,
    review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    time_spent_seconds INT,
    FOREIGN KEY (flashcard_id) REFERENCES flashcards(id) ON DELETE CASCADE,
    INDEX idx_flashcard_date (flashcard_id, review_date)
);
```

#### **8. key_takeaways**
```sql
CREATE TABLE key_takeaways (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_book_id BIGINT NOT NULL,
    content TEXT NOT NULL,
    page_number INT,
    order_index INT DEFAULT 0, -- Thứ tự hiển thị
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_book_id) REFERENCES user_books(id) ON DELETE CASCADE,
    INDEX idx_user_book (user_book_id, order_index)
);
```

#### **9. friends** (Vòng tròn tin cậy)
```sql
CREATE TABLE friends (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    friend_id BIGINT NOT NULL,
    status ENUM('PENDING', 'ACCEPTED', 'BLOCKED') DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (friend_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_friendship (user_id, friend_id),
    CHECK (user_id != friend_id), -- Không thể kết bạn với chính mình
    INDEX idx_user_status (user_id, status),
    INDEX idx_friend_status (friend_id, status)
);
```

#### **10. activities** (Hoạt động xã hội)
```sql
CREATE TABLE activities (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    activity_type ENUM(
        'BOOK_ADDED',
        'BOOK_STATUS_CHANGED',
        'BOOK_COMPLETED',
        'NOTE_CREATED',
        'REVIEW_POSTED',
        'PROGRESS_UPDATED'
    ) NOT NULL,
    book_id BIGINT,
    user_book_id BIGINT,
    note_id BIGINT,
    metadata JSON, -- Lưu thông tin bổ sung (rating, status, etc.)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE SET NULL,
    FOREIGN KEY (user_book_id) REFERENCES user_books(id) ON DELETE SET NULL,
    INDEX idx_user_created (user_id, created_at),
    INDEX idx_friends_feed (user_id, activity_type, created_at)
);
```

#### **11. activity_likes** (Like hoạt động)
```sql
CREATE TABLE activity_likes (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    activity_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (activity_id) REFERENCES activities(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_activity_like (activity_id, user_id),
    INDEX idx_activity (activity_id)
);
```

#### **12. activity_comments** (Comment hoạt động)
```sql
CREATE TABLE activity_comments (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    activity_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (activity_id) REFERENCES activities(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_activity (activity_id, created_at)
);
```

#### **13. notification_settings** (Cài đặt thông báo)
```sql
CREATE TABLE notification_settings (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL UNIQUE,
    enabled BOOLEAN DEFAULT TRUE,
    reminder_time TIME DEFAULT '20:00:00',
    reminder_days VARCHAR(20) DEFAULT '1,2,3,4,5', -- Comma-separated: 1=Monday, 7=Sunday
    sound_enabled BOOLEAN DEFAULT TRUE,
    vibration_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

---

## 🔌 API ENDPOINTS

### **Base URL:** `/api/v1`

### **1. Authentication & User Management**

#### **POST** `/auth/register`
Đăng ký tài khoản mới
```json
Request Body:
{
  "email": "user@example.com",
  "password": "password123",
  "fullName": "Nguyễn Văn A"
}

Response:
{
  "token": "jwt_token_here",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "fullName": "Nguyễn Văn A"
  }
}
```

#### **POST** `/auth/login`
Đăng nhập
```json
Request Body:
{
  "email": "user@example.com",
  "password": "password123"
}

Response:
{
  "token": "jwt_token_here",
  "refreshToken": "refresh_token_here",
  "user": { ... }
}
```

#### **POST** `/auth/refresh`
Refresh JWT token
```json
Request Body:
{
  "refreshToken": "refresh_token_here"
}
```

#### **POST** `/auth/logout`
Đăng xuất (invalidate token)

#### **GET** `/auth/me`
Lấy thông tin user hiện tại (JWT required)

#### **PUT** `/users/profile`
Cập nhật profile
```json
Request Body:
{
  "fullName": "Nguyễn Văn B",
  "bio": "Love reading books",
  "avatarUrl": "https://..."
}
```

---

### **2. Books Management**

#### **GET** `/books/search?q={query}&page={page}&size={size}`
Tìm kiếm sách (tích hợp Google Books API)
```json
Response:
{
  "content": [
    {
      "id": 1,
      "title": "Sách hay",
      "author": "Tác giả",
      "isbn": "1234567890",
      "coverImageUrl": "https://...",
      "description": "...",
      "pageCount": 300
    }
  ],
  "totalElements": 100,
  "totalPages": 10,
  "currentPage": 0
}
```

#### **GET** `/books/isbn/{isbn}`
Lấy thông tin sách từ ISBN (từ Google Books API)

#### **GET** `/books/{bookId}`
Lấy chi tiết sách

#### **POST** `/books`
Thêm sách mới (nếu không có trong DB)

---

### **3. User Books (Thư viện cá nhân)**

#### **GET** `/user-books?status={status}&page={page}&size={size}`
Lấy danh sách sách của user
- `status`: `WANT_TO_READ`, `READING`, `READ`, hoặc `ALL`

#### **POST** `/user-books`
Thêm sách vào thư viện
```json
Request Body:
{
  "bookId": 1,
  "status": "WANT_TO_READ",
  "location": "Kệ sách phòng khách" // Optional
}
```

#### **PUT** `/user-books/{userBookId}`
Cập nhật thông tin user book
```json
Request Body:
{
  "status": "READING",
  "currentPage": 150,
  "location": "Đã cho bạn A mượn",
  "rating": 5,
  "review": "Sách rất hay!"
}
```

#### **DELETE** `/user-books/{userBookId}`
Xóa sách khỏi thư viện

#### **GET** `/user-books/{userBookId}`
Lấy chi tiết user book

#### **GET** `/user-books/{userBookId}/friends`
Lấy danh sách bạn bè đã đọc sách này

---

### **4. Reading Progress**

#### **POST** `/user-books/{userBookId}/progress`
Cập nhật tiến độ đọc
```json
Request Body:
{
  "pageNumber": 150,
  "readingDate": "2024-12-26",
  "notes": "Đọc xong chương 5",
  "readingDurationMinutes": 45
}
```

#### **GET** `/user-books/{userBookId}/progress/history`
Lấy lịch sử cập nhật tiến độ

#### **GET** `/user-books/{userBookId}/stats`
Lấy thống kê đọc sách (tốc độ, dự kiến hoàn thành, etc.)

---

### **5. Notes**

#### **GET** `/notes?bookId={bookId}&page={page}&size={size}`
Lấy danh sách ghi chú
- Có thể filter theo `bookId`, `pageNumber`, `tags`

#### **GET** `/notes/{noteId}`
Lấy chi tiết ghi chú

#### **POST** `/notes`
Tạo ghi chú mới
```json
Request Body:
{
  "bookId": 1,
  "title": "Ý tưởng hay",
  "content": "Nội dung ghi chú...",
  "pageNumber": 150,
  "tags": "quan-trọng, self-help",
  "ocrImageUrl": "https://..." // Optional
}
```

#### **PUT** `/notes/{noteId}`
Cập nhật ghi chú

#### **DELETE** `/notes/{noteId}`
Xóa ghi chú

#### **POST** `/notes/{noteId}/convert-to-flashcard`
Chuyển ghi chú thành flashcard
```json
Response:
{
  "flashcardId": 1,
  "question": "Ý tưởng hay",
  "answer": "Nội dung ghi chú..."
}
```

---

### **6. Flashcards**

#### **GET** `/flashcards/due?page={page}&size={size}`
Lấy danh sách flashcard cần ôn hôm nay

#### **GET** `/flashcards?bookId={bookId}&deckName={deckName}`
Lấy danh sách flashcard (filter theo book hoặc deck)

#### **GET** `/flashcards/{flashcardId}`
Lấy chi tiết flashcard

#### **POST** `/flashcards`
Tạo flashcard thủ công
```json
Request Body:
{
  "bookId": 1,
  "question": "Câu hỏi?",
  "answer": "Câu trả lời",
  "deckName": "default"
}
```

#### **POST** `/flashcards/{flashcardId}/review`
Review flashcard (SM-2 algorithm)
```json
Request Body:
{
  "result": "REMEMBERED" // FORGOT, REMEMBERED, MASTERED
}

Response:
{
  "flashcardId": 1,
  "nextReviewDate": "2024-12-27",
  "intervalDays": 3,
  "easeFactor": 2.50
}
```

#### **GET** `/flashcards/stats`
Lấy thống kê flashcard (tổng số, cần ôn, % mastered)

#### **GET** `/flashcards/decks`
Lấy danh sách decks với số thẻ cần ôn

---

### **7. Key Takeaways**

#### **GET** `/user-books/{userBookId}/takeaways`
Lấy danh sách key takeaways

#### **POST** `/user-books/{userBookId}/takeaways`
Thêm key takeaway
```json
Request Body:
{
  "content": "Ý tưởng chính 1",
  "pageNumber": 50,
  "orderIndex": 0
}
```

#### **PUT** `/takeaways/{takeawayId}`
Cập nhật key takeaway

#### **DELETE** `/takeaways/{takeawayId}`
Xóa key takeaway

#### **PUT** `/takeaways/reorder`
Sắp xếp lại thứ tự
```json
Request Body:
{
  "takeawayIds": [3, 1, 2, 4]
}
```

---

### **8. Friends & Social**

#### **GET** `/friends?status={status}`
Lấy danh sách bạn bè
- `status`: `PENDING`, `ACCEPTED`, `ALL`

#### **POST** `/friends/request`
Gửi lời mời kết bạn
```json
Request Body:
{
  "friendId": 2
}
```

#### **PUT** `/friends/{friendshipId}/accept`
Chấp nhận lời mời kết bạn

#### **DELETE** `/friends/{friendshipId}`
Hủy kết bạn / Từ chối lời mời

#### **GET** `/friends/{friendId}/profile`
Xem profile bạn bè

#### **GET** `/friends/{friendId}/books`
Xem sách bạn bè đã đọc

---

### **9. Activities (Social Feed)**

#### **GET** `/activities/feed?page={page}&size={size}**
Lấy feed hoạt động của bạn bè
- Chỉ hiển thị activities của friends (status = ACCEPTED)

#### **POST** `/activities/{activityId}/like`
Like một activity

#### **DELETE** `/activities/{activityId}/like`
Unlike

#### **POST** `/activities/{activityId}/comments`
Thêm comment
```json
Request Body:
{
  "content": "Sách này hay quá!"
}
```

#### **GET** `/activities/{activityId}/comments`
Lấy danh sách comments

---

### **10. Notification Settings**

#### **GET** `/notifications/settings`
Lấy cài đặt thông báo

#### **PUT** `/notifications/settings`
Cập nhật cài đặt
```json
Request Body:
{
  "enabled": true,
  "reminderTime": "20:00:00",
  "reminderDays": "1,2,3,4,5", // Monday-Friday
  "soundEnabled": true,
  "vibrationEnabled": true
}
```

---

## 🔐 SECURITY & JWT

### **JWT Structure:**
```json
{
  "sub": "user@example.com",
  "userId": 1,
  "iat": 1703606400,
  "exp": 1703692800
}
```

### **Security Configuration:**
- **Password Encoding**: BCrypt (strength 10)
- **JWT Secret**: Lưu trong `application.properties` (hoặc environment variable)
- **JWT Expiration**: 
  - Access Token: 24 hours
  - Refresh Token: 7 days
- **CORS**: Cho phép frontend domain

### **Security Filter Chain:**
```
1. JWT Authentication Filter
2. Exception Handler Filter
3. CORS Filter
```

### **Public Endpoints** (không cần JWT):
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`

### **Protected Endpoints** (cần JWT):
- Tất cả endpoints khác

---

## 📁 CẤU TRÚC PROJECT

```
tram-doc-backend/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/
│   │   │       └── tramdoc/
│   │   │           ├── TramDocApplication.java
│   │   │           │
│   │   │           ├── config/
│   │   │           │   ├── SecurityConfig.java
│   │   │           │   ├── JwtConfig.java
│   │   │           │   ├── CorsConfig.java
│   │   │           │   └── WebConfig.java
│   │   │           │
│   │   │           ├── controller/
│   │   │           │   ├── AuthController.java
│   │   │           │   ├── BookController.java
│   │   │           │   ├── UserBookController.java
│   │   │           │   ├── NoteController.java
│   │   │           │   ├── FlashcardController.java
│   │   │           │   ├── KeyTakeawayController.java
│   │   │           │   ├── FriendController.java
│   │   │           │   ├── ActivityController.java
│   │   │           │   └── NotificationController.java
│   │   │           │
│   │   │           ├── service/
│   │   │           │   ├── AuthService.java
│   │   │           │   ├── UserService.java
│   │   │           │   ├── BookService.java
│   │   │           │   ├── UserBookService.java
│   │   │           │   ├── NoteService.java
│   │   │           │   ├── FlashcardService.java
│   │   │           │   ├── SpacedRepetitionService.java
│   │   │           │   ├── FriendService.java
│   │   │           │   ├── ActivityService.java
│   │   │           │   └── GoogleBooksService.java
│   │   │           │
│   │   │           ├── repository/
│   │   │           │   ├── UserRepository.java
│   │   │           │   ├── BookRepository.java
│   │   │           │   ├── UserBookRepository.java
│   │   │           │   ├── NoteRepository.java
│   │   │           │   ├── FlashcardRepository.java
│   │   │           │   ├── KeyTakeawayRepository.java
│   │   │           │   ├── FriendRepository.java
│   │   │           │   └── ActivityRepository.java
│   │   │           │
│   │   │           ├── entity/
│   │   │           │   ├── User.java
│   │   │           │   ├── Book.java
│   │   │           │   ├── UserBook.java
│   │   │           │   ├── Note.java
│   │   │           │   ├── Flashcard.java
│   │   │           │   ├── KeyTakeaway.java
│   │   │           │   ├── Friend.java
│   │   │           │   └── Activity.java
│   │   │           │
│   │   │           ├── dto/
│   │   │           │   ├── request/
│   │   │           │   │   ├── LoginRequest.java
│   │   │           │   │   ├── RegisterRequest.java
│   │   │           │   │   └── ...
│   │   │           │   └── response/
│   │   │           │       ├── AuthResponse.java
│   │   │           │       ├── BookResponse.java
│   │   │           │       └── ...
│   │   │           │
│   │   │           ├── security/
│   │   │           │   ├── JwtTokenProvider.java
│   │   │           │   ├── JwtAuthenticationFilter.java
│   │   │           │   └── UserPrincipal.java
│   │   │           │
│   │   │           ├── exception/
│   │   │           │   ├── GlobalExceptionHandler.java
│   │   │           │   ├── ResourceNotFoundException.java
│   │   │           │   └── BadRequestException.java
│   │   │           │
│   │   │           └── util/
│   │   │               ├── DateUtil.java
│   │   │               └── ValidationUtil.java
│   │   │
│   │   └── resources/
│   │       ├── application.properties
│   │       ├── application-dev.properties
│   │       ├── application-prod.properties
│   │       └── db/
│   │           └── migration/ (Flyway)
│   │               └── V1__Initial_schema.sql
│   │
│   └── test/
│       └── java/
│           └── com/tramdoc/
│               └── ... (Unit tests, Integration tests)
│
├── pom.xml (hoặc build.gradle)
├── README.md
└── .gitignore
```

---

## ⏱️ TIMELINE & PHASES

### **Phase 1: Foundation (Week 1-2)**
- ✅ Setup Spring Boot project
- ✅ Database schema design & migration
- ✅ JWT authentication setup
- ✅ User registration & login
- ✅ Basic security configuration

**Deliverables:**
- Working authentication API
- Database schema deployed
- JWT token generation & validation

---

### **Phase 2: Core Features - Books & Library (Week 3-4)**
- ✅ Book entity & repository
- ✅ Google Books API integration
- ✅ UserBook CRUD operations
- ✅ Reading progress tracking
- ✅ Book search & filter

**Deliverables:**
- Book management API
- User library API
- Reading progress API

---

### **Phase 3: Notes & Flashcards (Week 5-6)**
- ✅ Note CRUD operations
- ✅ OCR image storage (S3/Cloudinary)
- ✅ Flashcard entity & repository
- ✅ Spaced Repetition (SM-2) algorithm
- ✅ Flashcard review API

**Deliverables:**
- Note management API
- Flashcard system API
- SM-2 algorithm implementation

---

### **Phase 4: Social Features (Week 7-8)**
- ✅ Friend system (request/accept)
- ✅ Activity feed
- ✅ Like & comment system
- ✅ Friend profile API

**Deliverables:**
- Friend management API
- Social feed API
- Activity tracking

---

### **Phase 5: Advanced Features (Week 9-10)**
- ✅ Key takeaways
- ✅ Notification settings
- ✅ Statistics & analytics
- ✅ Search & filter enhancements

**Deliverables:**
- Complete feature set
- Performance optimization
- API documentation

---

### **Phase 6: Testing & Deployment (Week 11-12)**
- ✅ Unit tests
- ✅ Integration tests
- ✅ API documentation (Swagger)
- ✅ Deployment setup
- ✅ Performance testing

**Deliverables:**
- Production-ready API
- Complete documentation
- Deployed to server

---

## 📦 DEPENDENCIES

### **pom.xml (Maven)**
```xml
<dependencies>
    <!-- Spring Boot Starter Web -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    
    <!-- Spring Boot Starter Data JPA -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    
    <!-- MySQL Connector -->
    <dependency>
        <groupId>com.mysql</groupId>
        <artifactId>mysql-connector-j</artifactId>
        <scope>runtime</scope>
    </dependency>
    
    <!-- Spring Boot Starter Security -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>
    
    <!-- JWT -->
    <dependency>
        <groupId>io.jsonwebtoken</groupId>
        <artifactId>jjwt-api</artifactId>
        <version>0.11.5</version>
    </dependency>
    <dependency>
        <groupId>io.jsonwebtoken</groupId>
        <artifactId>jjwt-impl</artifactId>
        <version>0.11.5</version>
        <scope>runtime</scope>
    </dependency>
    <dependency>
        <groupId>io.jsonwebtoken</groupId>
        <artifactId>jjwt-jackson</artifactId>
        <version>0.11.5</version>
        <scope>runtime</scope>
    </dependency>
    
    <!-- Validation -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    
    <!-- Lombok -->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>
    
    <!-- Flyway (Database Migration) -->
    <dependency>
        <groupId>org.flywaydb</groupId>
        <artifactId>flyway-core</artifactId>
    </dependency>
    <dependency>
        <groupId>org.flywaydb</groupId>
        <artifactId>flyway-mysql</artifactId>
    </dependency>
    
    <!-- Swagger/OpenAPI -->
    <dependency>
        <groupId>org.springdoc</groupId>
        <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
        <version>2.2.0</version>
    </dependency>
    
    <!-- HTTP Client (for Google Books API) -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-webflux</artifactId>
    </dependency>
    
    <!-- Testing -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.springframework.security</groupId>
        <artifactId>spring-security-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

---

## 🔧 CONFIGURATION

### **application.properties**
```properties
# Server
server.port=8080
spring.application.name=tram-doc-api

# Database
spring.datasource.url=jdbc:mysql://localhost:3306/tram_doc_db?createDatabaseIfNotExist=true
spring.datasource.username=root
spring.datasource.password=your_password
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

# JPA
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQL8Dialect

# Flyway
spring.flyway.enabled=true
spring.flyway.locations=classpath:db/migration
spring.flyway.baseline-on-migrate=true

# JWT
jwt.secret=your-secret-key-change-in-production-min-256-bits
jwt.expiration=86400000
jwt.refresh-expiration=604800000

# Google Books API
google.books.api.key=your-api-key
google.books.api.url=https://www.googleapis.com/books/v1/volumes

# CORS
cors.allowed-origins=http://localhost:3000,http://localhost:5173

# File Upload
spring.servlet.multipart.max-file-size=10MB
spring.servlet.multipart.max-request-size=10MB
```

---

## 📝 NOTES

### **Best Practices:**
1. **Validation**: Sử dụng `@Valid` và `@NotNull` cho tất cả DTOs
2. **Error Handling**: Global exception handler với consistent error response format
3. **Pagination**: Tất cả list endpoints đều có pagination
4. **Logging**: Sử dụng SLF4J với Logback
5. **Testing**: Unit tests cho services, Integration tests cho controllers
6. **Documentation**: Swagger/OpenAPI cho API documentation

### **Performance:**
- Database indexing cho các queries thường dùng
- Caching cho Google Books API responses
- Lazy loading cho relationships
- Pagination để tránh load quá nhiều data

### **Security:**
- Password phải được hash bằng BCrypt
- JWT secret phải đủ mạnh (min 256 bits)
- Validate input để tránh SQL injection, XSS
- Rate limiting cho authentication endpoints

---

**Version:** 1.0.0  
**Last Updated:** December 26, 2024  
**Status:** Planning Phase

---

Made with ❤️ by Trạm Đọc Backend Team
