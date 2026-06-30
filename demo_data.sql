-- Trạm Đọc - Sample Data for Demo purposes
-- Execute this script manually to populate the database with sample data

-- 1. Insert Sample Users (Passwords are 'password123' bcrypt hashed)
INSERT INTO users (email, password, full_name, bio, is_active, created_at) VALUES 
('reader1@example.com', '$2a$10$wY.uV1G0h3gqO4OZYlIfxepf/s5wD1g.U/qA8e7xXpAOUW3wE7Pai', 'Nguyễn Văn Đọc', 'Yêu sách, thích cà phê, đam mê công nghệ', true, NOW()),
('reader2@example.com', '$2a$10$wY.uV1G0h3gqO4OZYlIfxepf/s5wD1g.U/qA8e7xXpAOUW3wE7Pai', 'Trần Thị Sách', 'Người sưu tầm tri thức', true, NOW()),
('reader3@example.com', '$2a$10$wY.uV1G0h3gqO4OZYlIfxepf/s5wD1g.U/qA8e7xXpAOUW3wE7Pai', 'Lê Hữu Cảm', 'Chuyên gia review sách dạo', true, NOW());

-- 2. Insert Sample Books
INSERT INTO books (title, author, cover_image_url, description, published_date, page_count, created_at) VALUES 
('Đắc Nhân Tâm', 'Dale Carnegie', 'https://m.media-amazon.com/images/I/71X4q9K8tPL._AC_UF1000,1000_QL80_.jpg', 'Cuốn sách nổi tiếng nhất mọi thời đại về nghệ thuật giao tiếp và thu phục lòng người.', '1936-10-01', 320, NOW()),
('Nhà Giả Kim', 'Paulo Coelho', 'https://m.media-amazon.com/images/I/71p0g0UDB1L._AC_UF1000,1000_QL80_.jpg', 'Hành trình đi tìm kho báu và khám phá bản thân của cậu bé chăn cừu Santiago.', '1988-01-01', 225, NOW()),
('Atomic Habits', 'James Clear', 'https://m.media-amazon.com/images/I/81bGKUa1e0L._AC_UF1000,1000_QL80_.jpg', 'Thay đổi tí hon, hiệu quả bất ngờ.', '2018-10-16', 320, NOW()),
('Clean Code', 'Robert C. Martin', 'https://m.media-amazon.com/images/I/41xShlnTZTL._AC_UF1000,1000_QL80_.jpg', 'A Handbook of Agile Software Craftsmanship.', '2008-08-11', 464, NOW());

-- 3. Insert User Books (Shelves)
-- User 1 reading Clean Code, finished Atomic Habits, wants to read Đắc Nhân Tâm
INSERT INTO user_books (user_id, book_id, status, current_page, total_pages, rating, review, started_at) VALUES 
(1, 4, 'READING', 120, 464, NULL, NULL, NOW()),
(1, 3, 'READ', 320, 320, 5, 'Rất hay và thiết thực cho việc xây dựng thói quen tốt.', DATE_SUB(NOW(), INTERVAL 1 MONTH)),
(1, 1, 'WANT_TO_READ', 0, 320, NULL, NULL, NOW());

-- User 2 reading Nhà Giả Kim
INSERT INTO user_books (user_id, book_id, status, current_page, total_pages, rating, review, started_at) VALUES 
(2, 2, 'READING', 50, 225, NULL, NULL, NOW());

-- 4. Insert Friendships
-- User 1 and User 2 are friends
INSERT INTO friends (user_id, friend_id, status, created_at) VALUES 
(1, 2, 'ACCEPTED', NOW()),
(2, 1, 'ACCEPTED', NOW());

-- User 3 pending request to User 1
INSERT INTO friends (user_id, friend_id, status, created_at) VALUES 
(3, 1, 'PENDING', NOW());

-- 5. Insert Activities
INSERT INTO activities (user_id, activity_type, book_id, user_book_id, metadata, created_at) VALUES
(1, 'REVIEW_POSTED', 3, 2, '{"review": "Vừa đọc xong Atomic Habits. Thật sự thay đổi cách mình làm việc!"}', DATE_SUB(NOW(), INTERVAL 2 DAY)),
(2, 'BOOK_ADDED', 2, 4, '{"message": "Bắt đầu hành trình đi tìm kho báu cùng Santiago."}', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(1, 'PROGRESS_UPDATED', 4, 1, '{"current_page": 120, "message": "Đã đọc được 120 trang Clean Code. Code của mình bắt đầu sạch hơn rồi."}', NOW());
