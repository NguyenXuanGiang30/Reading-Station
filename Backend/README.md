# 📚 Trạm Đọc - Backend API

> **Spring Boot + MySQL + JWT Authentication**

## 🚀 Getting Started

### Prerequisites
- Java 17+
- Maven 3.8+
- MySQL 8.0+
- IDE (IntelliJ IDEA / Eclipse / VS Code)

### Setup

1. **Clone repository**
```bash
cd Backend
```

2. **Create MySQL Database**
```sql
CREATE DATABASE tram_doc_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

3. **Configure Database**
Edit `src/main/resources/application.properties`:
```properties
spring.datasource.username=root
spring.datasource.password=your_password
```

4. **Run Application**
```bash
mvn spring-boot:run
```

5. **Access API**
- API Base URL: `http://localhost:8080/api/v1`
- Swagger UI: `http://localhost:8080/swagger-ui.html`
- API Docs: `http://localhost:8080/api-docs`

## 📋 API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Đăng ký
- `POST /api/v1/auth/login` - Đăng nhập

## 🏗️ Project Structure

```
src/main/java/com/tramdoc/
├── config/          # Configuration classes
├── controller/      # REST Controllers
├── service/         # Business logic
├── repository/      # Data access layer
├── entity/          # JPA entities
├── dto/             # Data Transfer Objects
├── security/        # Security & JWT
└── exception/       # Exception handling
```

## 🔐 Security

- JWT Authentication
- BCrypt password encoding
- CORS enabled for frontend

## 📝 Database Migration

Flyway is configured to run migrations automatically from `src/main/resources/db/migration/`

## 🧪 Testing

```bash
mvn test
```

## 📚 Documentation

See `doc/BACKEND_API_PLAN.md` for detailed API documentation.

---

**Version:** 1.0.0  
**Status:** Development
