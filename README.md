# 📚 TRẠM ĐỌC - ỨNG DỤNG QUẢN LÝ SÁCH & GHI CHÚ THÔNG MINH

> **"Đọc sách, ghi chú, ôn tập thông minh"**

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Backend](https://img.shields.io/badge/Backend-Spring%20Boot%203.2-green)
![Frontend](https://img.shields.io/badge/Frontend-Flutter%203.10-blue)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 📋 Mục lục

- [Giới thiệu](#-giới-thiệu)
- [Tính năng chính](#-tính-năng-chính)
- [Kiến trúc hệ thống](#-kiến-trúc-hệ-thống)
- [Cài đặt và Chạy](#-cài-đặt-và-chạy)
- [API Documentation](#-api-documentation)
- [Cấu trúc dự án](#-cấu-trúc-dự-án)
- [Công nghệ sử dụng](#-công-nghệ-sử-dụng)
- [Đóng góp](#-đóng-góp)

---

## 🎯 Giới thiệu

**Trạm Đọc** là ứng dụng di động được thiết kế để giải quyết hai vấn đề lớn nhất của người đọc sách:

- **"Tôi không nhớ mình đã đọc gì"**
- **"Tôi không biết mình nên đọc gì tiếp theo"**

Ứng dụng hoạt động như một **trợ lý thư viện cá nhân**, giúp người dùng:

- 📚 Quản lý tủ sách (cả sách giấy và ebook)
- ✍️ Ghi chú thông minh với OCR
- 🧠 Ôn tập kiến thức với hệ thống Flashcard
- 👥 Kết nối với bạn bè trong Vòng tròn Tin cậy

---

## ✨ Tính năng chính

### 📚 1. Thư viện Cá nhân (Personal Library)

- **Thêm sách thông minh**: Tìm kiếm hoặc quét mã vạch ISBN
- **3 kệ sách**: Muốn đọc | Đang đọc | Hoàn thành
- **Theo dõi tiến độ**: Cập nhật số trang đã đọc
- **Vị trí sách**: Ghi nhớ vị trí sách giấy
- **Tích hợp Google Books API**: Tự động lấy thông tin sách

### ✍️ 2. Ghi chú Thông minh (Smart Notes)

- **Ghi chú văn bản**: Rich text editor với formatting
- **OCR Camera**: Chụp ảnh sách, trích xuất text tự động
- **Gắn số trang**: Tự động đính kèm vị trí ghi chú
- **Key Takeaways**: Tóm tắt ý chính sau khi đọc xong

### 🧠 3. Ôn tập Flashcard (Spaced Repetition)

- **Thuật toán SM-2**: Lịch ôn tập tối ưu (giống Anki)
- **Chuyển ghi chú thành Flashcard**: 1-click convert
- **3 mức đánh giá**: Quên | Nhớ | Thuộc
- **Thông báo nhắc nhở**: Ôn tập hàng ngày

### 👥 4. Vòng tròn Tin cậy (Reading Circle)

- **Mạng xã hội thu nhỏ**: Kết bạn với người tin tưởng
- **Feed chất lượng**: Xem hoạt động đọc sách của bạn bè
- **Gợi ý cá nhân hóa**: "3 bạn bè đã đọc cuốn sách này"

---

## 🏗️ Kiến trúc hệ thống

```
+-------------------+     HTTP/REST      +-------------------+
|                   | <----------------> |                   |
|   Flutter App     |                    |   Spring Boot     |
|   (Frontend)      |                    |   API (Backend)   |
|                   |                    |                   |
+-------------------+                    +---------+---------+
                                                  |
                                                  | JPA/Hibernate
                                                  v
                                         +-------------------+
                                         |                   |
                                         |      MySQL        |
                                         |    Database       |
                                         |                   |
                                         +-------------------+
```

---

## 🚀 Cài đặt và Chạy

### Yêu cầu hệ thống

- Java 17+
- Maven 3.8+
- Flutter 3.10+
- MySQL 8.0+
- Android Studio / VS Code

### 1. Backend (Spring Boot)

```bash
# Clone repository
git clone https://github.com/NguyenXuanGiang30/Reading-Station.git
cd Reading-Station/Backend

# Tạo database
mysql -u root -p -e "CREATE DATABASE tram_doc_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Cấu hình database (edit file src/main/resources/application.properties)
# spring.datasource.username=root
# spring.datasource.password=your_password

# Chạy ứng dụng
mvn spring-boot:run
```

**Truy cập API đã deploy:**

- API Base: https://api.tuyendungvn.id.vn/api/v1
- Swagger UI: https://api.tuyendungvn.id.vn/swagger-ui/index.html

### 2. Frontend (Flutter)

```bash
cd Reading-Station/frontend

# Cài đặt dependencies
flutter pub get

# Chạy ứng dụng (Android/iOS)
flutter run

# Build APK
flutter build apk --release
```

---

## 📖 API Documentation

### Authentication

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | /api/v1/auth/register | Đăng ký tài khoản |
| POST | /api/v1/auth/login | Đăng nhập |

### Books và Library

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | /api/v1/books | Danh sách sách |
| GET | /api/v1/books/search?q=query | Tìm kiếm sách |
| GET | /api/v1/books/isbn/isbn | Lấy sách từ ISBN |
| GET | /api/v1/user-books | Thư viện cá nhân |
| POST | /api/v1/user-books | Thêm sách vào thư viện |
| PUT | /api/v1/user-books/id | Cập nhật sách |
| DELETE | /api/v1/user-books/id | Xóa sách |

### Notes

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | /api/v1/notes | Danh sách ghi chú |
| POST | /api/v1/notes | Tạo ghi chú mới |
| PUT | /api/v1/notes/id | Cập nhật ghi chú |
| DELETE | /api/v1/notes/id | Xóa ghi chú |

### Flashcards

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | /api/v1/flashcards/due | Flashcard cần ôn hôm nay |
| POST | /api/v1/flashcards | Tạo flashcard |
| POST | /api/v1/flashcards/id/review | Review flashcard (SM-2) |
| GET | /api/v1/flashcards/stats | Thống kê ôn tập |

📚 **Xem đầy đủ API tại:** https://api.tuyendungvn.id.vn/swagger-ui/index.html

---

## 📁 Cấu trúc dự án

```
Reading-Station/
├── Backend/                        # Spring Boot API
│   ├── src/main/java/com/tramdoc/
│   │   ├── config/                 # Cấu hình (Security, CORS)
│   │   ├── controller/             # REST Controllers
│   │   ├── service/                # Business logic
│   │   ├── repository/             # Data access layer
│   │   ├── entity/                 # JPA Entities
│   │   ├── dto/                    # Request/Response DTOs
│   │   ├── security/               # JWT Authentication
│   │   └── exception/              # Exception handlers
│   ├── src/main/resources/
│   │   ├── application.properties
│   │   └── db/migration/           # Flyway migrations
│   ├── doc/                        # Tài liệu dự án
│   ├── Dockerfile
│   └── pom.xml
│
├── frontend/                       # Flutter Mobile App
│   ├── lib/
│   │   ├── blocs/                  # BLoC State Management
│   │   ├── models/                 # Data Models
│   │   ├── screens/                # UI Screens
│   │   ├── services/               # API Services
│   │   ├── theme/                  # App Theme
│   │   ├── config/                 # App Configuration
│   │   ├── router.dart             # Navigation (GoRouter)
│   │   └── main.dart
│   ├── assets/                     # Images, Icons, Animations
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
└── README.md
```

---

## 🛠️ Công nghệ sử dụng

### Backend

| Công nghệ | Phiên bản | Mục đích |
|-----------|-----------|----------|
| Spring Boot | 3.2.x | Framework chính |
| Spring Security | 6.x | Authentication và Authorization |
| JWT | - | Token-based auth |
| Flyway | 9.x | Database migration |
| MySQL | 8.0+ | Database chính |
| Swagger/OpenAPI | 3.0 | API Documentation |

### Frontend

| Công nghệ | Phiên bản | Mục đích |
|-----------|-----------|----------|
| Flutter | 3.10.x | Cross-platform framework |
| flutter_bloc | 8.x | State management |
| dio | 5.x | HTTP client |
| go_router | 14.x | Navigation |
| mobile_scanner | 7.x | Barcode scanning |
| google_mlkit_text_recognition | 0.13.x | OCR |
| fl_chart | 0.69.x | Charts và graphs |
| flutter_local_notifications | 17.x | Push notifications |

---

## 🗄️ Database Schema

Dự án sử dụng 13 bảng dữ liệu chính:

| Bảng | Mô tả |
|------|-------|
| users | Thông tin người dùng |
| books | Catalog sách |
| user_books | Thư viện cá nhân (3 kệ sách) |
| reading_progress | Lịch sử đọc sách |
| notes | Ghi chú với OCR support |
| flashcards | Flashcard với SM-2 algorithm |
| flashcard_reviews | Lịch sử ôn tập |
| key_takeaways | Key points của sách |
| friends | Quan hệ bạn bè |
| activities | Hoạt động xã hội |
| activity_likes | Like hoạt động |
| activity_comments | Bình luận |
| notification_settings | Cài đặt thông báo |

---

## 🔐 Bảo mật

- JWT Authentication: Token-based security
- BCrypt Password: Mã hóa mật khẩu
- CORS Configuration: Bảo vệ API calls
- Role-based Access: Phân quyền người dùng

---

## 🚢 Deployment

### Docker

```bash
cd Backend
docker build -t tramdoc-api .
docker run -p 8080:8080 tramdoc-api
```

### Cloudflare Tunnel

Xem hướng dẫn chi tiết: [CLOUDFLARE_TUNNEL_GUIDE.md](Backend/doc/CLOUDFLARE_TUNNEL_GUIDE.md)

### Render.com

Xem hướng dẫn chi tiết: [RENDER_DEPLOYMENT_GUIDE.md](Backend/doc/RENDER_DEPLOYMENT_GUIDE.md)

---

## 🤝 Đóng góp

Chúng tôi hoan nghênh mọi đóng góp! Hãy:

1. Fork repository
2. Tạo branch mới: `git checkout -b feature/AmazingFeature`
3. Commit changes: `git commit -m 'Add some AmazingFeature'`
4. Push to branch: `git push origin feature/AmazingFeature`
5. Mở Pull Request

---

## 📄 License

Dự án được phân phối dưới giấy phép MIT.

---

## 📞 Liên hệ

- **API Docs**: https://api.tuyendungvn.id.vn/swagger-ui/index.html
- **GitHub**: https://github.com/NguyenXuanGiang30/Reading-Station

---

Made with ❤️ by Trạm Đọc Team