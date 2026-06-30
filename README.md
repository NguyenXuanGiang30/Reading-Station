# Trạm Đọc (Reading Station)

Ứng dụng đọc sách di động với tính năng quản lý sách, ghi chú, flashcard và mạng xã hội cho người đọc.

## Mục lục

- [Giới thiệu](#giới-thiệu)
- [Công nghệ](#công-nghệ)
- [Cấu trúc dự án](#cấu-trúc-dự-án)
- [Cài đặt](#cài-đặt)
  - [Yêu cầu](#yêu-cầu)
  - [Backend](#backend)
  - [Frontend](#frontend)
- [Chạy ứng dụng](#chạy-ứng-dụng)
- [Docker](#docker)
- [API Documentation](#api-documentation)
- [Đóng góp](#đóng-góp)
- [License](#license)

## Giới thiệu

Trạm Đọc là ứng dụng giúp người dùng:
- Quản lý thư viện sách cá nhân
- Tạo ghi chú khi đọc
- Tạo flashcard để ôn tập
- Theo dõi tiến độ đọc
- Kết nối với bạn bè qua mạng xã hội

## Công nghệ

### Backend
- Java 17
- Spring Boot 3.2.0
- MySQL 8.0
- JWT Authentication
- Maven

### Frontend
- Flutter 3.x
- Dart
- BLoC Pattern

## Cấu trúc dự án

```
Reading_Station/
├── Backend/                 # Spring Boot API
│   ├── src/
│   │   └── main/
│   │       ├── java/com/tramdoc/
│   │       └── resources/
│   │           └── application.yml
│   ├── Dockerfile
│   └── pom.xml
├── frontend/               # Flutter App
│   ├── lib/
│   │   ├── config/        # Configuration
│   │   ├── models/        # Data models
│   │   ├── services/      # API services
│   │   ├── screens/       # UI screens
│   │   └── widgets/       # Reusable widgets
│   ├── pubspec.yaml
│   └── android/           # Android build config
├── docker-compose.yml      # Docker compose
├── .github/
│   └── workflows/         # CI/CD
└── README.md
```

## Cài đặt

### Yêu cầu

- Java 17+
- Maven 3.9+
- Flutter 3.x
- Docker & Docker Compose
- MySQL 8.0 (nếu không dùng Docker)

### Backend

1. Clone repository:
```bash
git clone https://github.com/your-repo/Reading_Station.git
cd Reading_Station
```

2. Cấu hình database:
```bash
cd Backend
cp src/main/resources/application.yml.example src/main/resources/application.yml
# Chỉnh sửa application.yml với thông tin database của bạn
```

3. Build và chạy:
```bash
mvn clean install
mvn spring-boot:run
```

Backend sẽ chạy tại `http://localhost:8080`

### Frontend

1. Cài đặt Flutter dependencies:
```bash
cd frontend
flutter pub get
```

2. Cấu hình API URL:
```bash
# Chỉnh sửa lib/config/environment.dart
```

3. Chạy ứng dụng:
```bash
flutter run
```

## Chạy ứng dụng

### Chạy với Docker (Khuyến nghị)

1. Cấu hình environment:
```bash
cp .env.example .env
# Chỉnh sửa .env với các giá trị của bạn
```

2. Chạy Docker Compose:
```bash
docker-compose up -d
```

3. Kiểm tra:
- Backend: http://localhost:8080
- MySQL: localhost:3306

### Chạy riêng lẻ

#### Backend
```bash
cd Backend
mvn spring-boot:run
```

#### Frontend
```bash
cd frontend
flutter run
```

## Docker

### Build Docker Image

```bash
# Backend
docker build -t tramdoc-backend ./Backend

# Frontend (Android)
docker build -t tramdoc-app ./frontend
```

### Docker Compose

```bash
# Chạy tất cả services
docker-compose up -d

# Xem logs
docker-compose logs -f

# Dừng
docker-compose down
```

## API Documentation

### Base URL
```
Production: https://api.tuyendungvn.id.vn/api/v1
Development: http://localhost:8080/api/v1
```

### Authentication Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/login` | Đăng nhập |
| POST | `/auth/register` | Đăng ký |
| POST | `/auth/refresh` | Refresh token |
| POST | `/auth/logout` | Đăng xuất |
| POST | `/auth/google` | Login với Google |
| POST | `/auth/facebook` | Login với Facebook |

### User Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/users/me` | Lấy thông tin user |
| PUT | `/users/profile` | Cập nhật profile |
| GET | `/users/search` | Tìm kiếm user |

### Book Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/books` | Lấy danh sách sách |
| GET | `/books/{id}` | Lấy chi tiết sách |
| POST | `/books` | Thêm sách mới |
| PUT | `/books/{id}` | Cập nhật sách |
| DELETE | `/books/{id}` | Xóa sách |
| GET | `/books/isbn/{isbn}` | Tìm sách theo ISBN |

### Note Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/notes` | Lấy danh sách ghi chú |
| POST | `/notes` | Tạo ghi chú |
| PUT | `/notes/{id}` | Cập nhật ghi chú |
| DELETE | `/notes/{id}` | Xóa ghi chú |

### Flashcard Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/flashcards/due` | Lấy cards cần ôn |
| POST | `/flashcards` | Tạo flashcard |
| POST | `/flashcards/{id}/review` | Nộp kết quả ôn tập |
| GET | `/flashcards/stats` | Lấy thống kê |

### Social Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/friends` | Lấy danh sách bạn bè |
| POST | `/friends/request/{id}` | Gửi lời mời kết bạn |
| GET | `/activities/feed` | Lấy feed hoạt động |

## Đóng góp

1. Fork repository
2. Tạo branch mới (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add some amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Tạo Pull Request

## License

Distributed under the MIT License.

---

Made with ❤️ by Trạm Đọc Team
