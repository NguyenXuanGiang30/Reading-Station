# 📚 Hướng Dẫn Deploy Trạm Đọc API lên Render.com (MIỄN PHÍ)

## ⭐ Tại sao chọn Render?

| Tính năng | Render (Free) | Heroku |
|-----------|---------------|--------|
| Cần thẻ tín dụng | ❌ Không | ✅ Có |
| Free tier | ✅ Có (750 giờ/tháng) | ❌ Không còn |
| MySQL miễn phí | ❌ Không (dùng PostgreSQL) | ❌ Không |
| PostgreSQL miễn phí | ✅ Có (90 ngày) | ❌ Không |
| Auto deploy từ GitHub | ✅ Có | ✅ Có |
| SSL miễn phí | ✅ Có | ✅ Có |

---

## 📋 Mục Lục
1. [Chuẩn Bị Project](#1-chuẩn-bị-project)
2. [Đăng Ký Render](#2-đăng-ký-render)
3. [Tạo Database PostgreSQL](#3-tạo-database-postgresql)
4. [Deploy Web Service](#4-deploy-web-service)
5. [Cấu Hình Environment Variables](#5-cấu-hình-environment-variables)
6. [Kiểm Tra và Test](#6-kiểm-tra-và-test)

---

## 1. Chuẩn Bị Project

### 1.1. Thêm PostgreSQL Driver vào `pom.xml`

Render cung cấp PostgreSQL miễn phí. Thêm driver:

```xml
<!-- PostgreSQL Driver (cho Render) -->
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>
```

### 1.2. Cập nhật `application.properties`

```properties
# ============================================
# SERVER CONFIGURATION
# ============================================
server.port=${PORT:8080}
spring.application.name=tram-doc-api

# ============================================
# DATABASE CONFIGURATION
# ============================================
spring.datasource.url=${DATABASE_URL:jdbc:mysql://localhost:3306/tram_doc_db?createDatabaseIfNotExist=true&useSSL=false&serverTimezone=Asia/Ho_Chi_Minh&allowPublicKeyRetrieval=true}
spring.datasource.username=${DATABASE_USERNAME:root}
spring.datasource.password=${DATABASE_PASSWORD:giang2005}

# ============================================
# JPA/HIBERNATE CONFIGURATION
# ============================================
spring.jpa.hibernate.ddl-auto=${DDL_AUTO:update}
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.format_sql=true
# Hibernate tự detect dialect

# ============================================
# FLYWAY CONFIGURATION
# ============================================
spring.flyway.enabled=${FLYWAY_ENABLED:true}
spring.flyway.locations=classpath:db/migration
spring.flyway.baseline-on-migrate=true

# ============================================
# JWT CONFIGURATION
# ============================================
jwt.secret=${JWT_SECRET:your-secret-key-change-in-production-min-256-bits}
jwt.expiration=86400000
jwt.refresh-expiration=604800000

# ============================================
# GOOGLE BOOKS API
# ============================================
google.books.api.key=${GOOGLE_BOOKS_API_KEY:}
google.books.api.url=https://www.googleapis.com/books/v1/volumes

# ============================================
# CORS CONFIGURATION  
# ============================================
cors.allowed-origins=${CORS_ORIGINS:*}

# ============================================
# SWAGGER/OPENAPI CONFIGURATION
# ============================================
springdoc.api-docs.path=/api-docs
springdoc.swagger-ui.path=/swagger-ui.html

# ============================================
# ACTUATOR CONFIGURATION
# ============================================
management.endpoints.web.exposure.include=health,info
```

### 1.3. Tạo file `render.yaml` (tùy chọn - cho Infrastructure as Code)

```yaml
services:
  - type: web
    name: tram-doc-api
    env: docker
    plan: free
    healthCheckPath: /actuator/health
    envVars:
      - key: JWT_SECRET
        generateValue: true
      - key: DATABASE_URL
        fromDatabase:
          name: tram-doc-db
          property: connectionString

databases:
  - name: tram-doc-db
    plan: free
```

### 1.4. Tạo `Dockerfile`

```dockerfile
FROM eclipse-temurin:17-jdk-alpine as build
WORKDIR /app
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
RUN chmod +x mvnw
RUN ./mvnw dependency:go-offline
COPY src ./src
RUN ./mvnw package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 1.5. Push code lên GitHub

```bash
# Khởi tạo Git (nếu chưa có)
git init
git add .
git commit -m "Prepare for Render deployment"

# Tạo repo trên GitHub và push
# Vào https://github.com/new tạo repo mới
git remote add origin https://github.com/YOUR_USERNAME/tram-doc-api.git
git branch -M main
git push -u origin main
```

---

## 2. Đăng Ký Render

1. Truy cập: https://render.com/
2. Click **"Get Started for Free"**
3. Đăng ký bằng **GitHub** (khuyến khích) hoặc Email
4. Xác nhận email

---

## 3. Tạo Database PostgreSQL

### 3.1. Tạo PostgreSQL Instance

1. Vào Dashboard: https://dashboard.render.com/
2. Click **"New +"** → **"PostgreSQL"**
3. Điền thông tin:
   - **Name**: `tram-doc-db`
   - **Database**: `tram_doc_db`
   - **User**: `tram_doc_user`
   - **Region**: Singapore (gần Việt Nam)
   - **Plan**: **Free** (90 ngày, sau đó cần upgrade hoặc tạo mới)

4. Click **"Create Database"**

### 3.2. Lấy Connection String

Sau khi tạo xong, vào tab **"Info"** và copy:
- **Internal Database URL** (dùng cho Web Service cùng region)
- **External Database URL** (dùng để test từ local)

Ví dụ:
```
postgresql://tram_doc_user:password123@dpg-abc123.singapore-postgres.render.com/tram_doc_db
```

---

## 4. Deploy Web Service

### 4.1. Tạo Web Service

1. Click **"New +"** → **"Web Service"**
2. Chọn **"Build and deploy from a Git repository"**
3. Connect GitHub account (nếu chưa)
4. Chọn repository **tram-doc-api**

### 4.2. Cấu hình Build

| Trường | Giá trị |
|--------|---------|
| **Name** | `tram-doc-api` |
| **Region** | Singapore |
| **Branch** | `main` |
| **Runtime** | Docker |
| **Instance Type** | Free |

### 4.3. Hoặc dùng Native Build (không cần Dockerfile)

| Trường | Giá trị |
|--------|---------|
| **Runtime** | Java |
| **Build Command** | `./mvnw clean package -DskipTests` |
| **Start Command** | `java -jar target/*.jar` |

---

## 5. Cấu Hình Environment Variables

Trong phần **"Environment"** của Web Service, thêm các biến:

| Key | Value | Ghi chú |
|-----|-------|---------|
| `DATABASE_URL` | `jdbc:postgresql://dpg-xxx.singapore-postgres.render.com/tram_doc_db` | Thêm `jdbc:` vào đầu |
| `DATABASE_USERNAME` | `tram_doc_user` | Từ PostgreSQL |
| `DATABASE_PASSWORD` | `password123` | Từ PostgreSQL |
| `JWT_SECRET` | `YourSuperSecretKey...` | Tự tạo, ít nhất 256 bit |
| `DDL_AUTO` | `update` | Tự tạo bảng |
| `FLYWAY_ENABLED` | `false` | Tắt Flyway (dùng DDL_AUTO) |
| `CORS_ORIGINS` | `*` | Hoặc domain frontend |

### ⚠️ Quan trọng: Chuyển đổi DATABASE_URL

Render cung cấp URL dạng:
```
postgresql://user:password@host/database
```

Bạn cần chuyển thành JDBC URL:
```
jdbc:postgresql://host/database
```

Và tách username/password riêng.

---

## 6. Kiểm Tra và Test

### 6.1. Theo dõi Deploy

- Vào tab **"Events"** để xem log build
- Vào tab **"Logs"** để xem runtime logs

### 6.2. URLs sau khi deploy

| URL | Mô tả |
|-----|-------|
| `https://tram-doc-api.onrender.com` | API Server |
| `https://tram-doc-api.onrender.com/swagger-ui/index.html` | Swagger UI |
| `https://tram-doc-api.onrender.com/actuator/health` | Health Check |

### 6.3. Test API

```bash
# Health Check
curl https://tram-doc-api.onrender.com/actuator/health

# Register
curl -X POST https://tram-doc-api.onrender.com/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","fullName":"Test User"}'

# Login
curl -X POST https://tram-doc-api.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

---

## ⚠️ Lưu Ý Quan Trọng

### Free Tier Limitations:

1. **Web Service**:
   - Sleep sau 15 phút không hoạt động
   - Cold start mất ~30 giây
   - 750 giờ miễn phí/tháng

2. **PostgreSQL**:
   - Miễn phí 90 ngày
   - Sau đó cần tạo mới hoặc upgrade ($7/tháng)
   - 256MB RAM, 1GB storage

### Giữ app "thức":

Dùng cron job ping mỗi 10 phút:
- https://cron-job.org/ (miễn phí)
- https://uptimerobot.com/ (miễn phí)

---

## 🔧 Xử Lý Lỗi Thường Gặp

### Lỗi: Database connection failed
- Kiểm tra DATABASE_URL đã thêm `jdbc:` chưa
- Kiểm tra username/password đúng chưa

### Lỗi: Build failed
- Kiểm tra Java version trong Dockerfile
- Thử build local trước: `./mvnw clean package -DskipTests`

### Lỗi: App crash sau deploy
- Xem Logs để biết lỗi cụ thể
- Kiểm tra environment variables

---

## 📊 So Sánh Các Nền Tảng Miễn Phí

| Nền tảng | Database Free | Sleep? | Dễ dùng |
|----------|--------------|--------|---------|
| **Render** | PostgreSQL 90 ngày | 15 phút | ⭐⭐⭐⭐⭐ |
| **Railway** | PostgreSQL $5 credit | Không | ⭐⭐⭐⭐ |
| **Fly.io** | PostgreSQL giới hạn | Không | ⭐⭐⭐ |
| **Koyeb** | Không | Không | ⭐⭐⭐⭐ |

---

**Chúc bạn deploy thành công! 🚀**
