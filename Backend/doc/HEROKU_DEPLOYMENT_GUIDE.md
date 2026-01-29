# 📚 Hướng Dẫn Deploy Trạm Đọc API lên Heroku

## 📋 Mục Lục
1. [Yêu Cầu Chuẩn Bị](#1-yêu-cầu-chuẩn-bị)
2. [Cài Đặt Heroku CLI](#2-cài-đặt-heroku-cli)
3. [Tạo Tài Khoản Heroku](#3-tạo-tài-khoản-heroku)
4. [Cấu Hình Project](#4-cấu-hình-project)
5. [Tạo App trên Heroku](#5-tạo-app-trên-heroku)
6. [Cấu Hình Database MySQL](#6-cấu-hình-database-mysql)
7. [Deploy Ứng Dụng](#7-deploy-ứng-dụng)
8. [Kiểm Tra và Xử Lý Lỗi](#8-kiểm-tra-và-xử-lý-lỗi)
9. [Các Lệnh Heroku Thường Dùng](#9-các-lệnh-heroku-thường-dùng)

---

## 1. Yêu Cầu Chuẩn Bị

### Phần mềm cần cài đặt:
- ✅ **Git** - [Download Git](https://git-scm.com/downloads)
- ✅ **Heroku CLI** - [Download Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli)
- ✅ **Java JDK 17+** (đã có sẵn trong project)

### Kiểm tra Git đã cài đặt:
```bash
git --version
# Output: git version 2.x.x
```

---

## 2. Cài Đặt Heroku CLI

### Windows:
1. Tải file installer từ: https://devcenter.heroku.com/articles/heroku-cli
2. Chạy file `.exe` và làm theo hướng dẫn
3. Restart terminal/PowerShell

### Kiểm tra cài đặt:
```bash
heroku --version
# Output: heroku/8.x.x win32-x64 node-v18.x.x
```

---

## 3. Tạo Tài Khoản Heroku

1. Truy cập: https://signup.heroku.com/
2. Đăng ký tài khoản miễn phí
3. Xác nhận email
4. Đăng nhập vào Heroku CLI:

```bash
heroku login
```
> Lệnh này sẽ mở trình duyệt để bạn đăng nhập

---

## 4. Cấu Hình Project

### 4.1. Tạo file `system.properties`

Tạo file `system.properties` ở thư mục gốc của project:

```properties
java.runtime.version=17
```

### 4.2. Tạo file `Procfile`

Tạo file `Procfile` (không có đuôi file) ở thư mục gốc:

```
web: java -Dserver.port=$PORT -jar target/*.jar
```

### 4.3. Cập nhật `application.properties`

Thêm profile cho production trong `src/main/resources/application.properties`:

```properties
# ============================================
# COMMON CONFIGURATION
# ============================================
spring.application.name=tram-doc-api

# ============================================
# SERVER CONFIGURATION
# ============================================
server.port=${PORT:8080}

# ============================================
# DATABASE CONFIGURATION (sẽ được override bởi Heroku)
# ============================================
spring.datasource.url=${JDBC_DATABASE_URL:jdbc:mysql://localhost:3306/tram_doc_db?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true}
spring.datasource.username=${JDBC_DATABASE_USERNAME:root}
spring.datasource.password=${JDBC_DATABASE_PASSWORD:giang2005}
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

# ============================================
# JPA/HIBERNATE CONFIGURATION
# ============================================
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQLDialect
spring.jpa.properties.hibernate.format_sql=true

# ============================================
# FLYWAY CONFIGURATION
# ============================================
spring.flyway.enabled=true
spring.flyway.baseline-on-migrate=true
spring.flyway.locations=classpath:db/migration

# ============================================
# JWT CONFIGURATION
# ============================================
jwt.secret=${JWT_SECRET:mySecretKeyForJWTTokenGenerationThatIsAtLeast256BitsLong123456789}
jwt.expiration=86400000
jwt.refresh-expiration=604800000

# ============================================
# GOOGLE BOOKS API
# ============================================
google.books.api.key=${GOOGLE_BOOKS_API_KEY:}
google.books.api.url=https://www.googleapis.com/books/v1/volumes

# ============================================
# SPRINGDOC/SWAGGER CONFIGURATION
# ============================================
springdoc.api-docs.path=/api-docs
springdoc.swagger-ui.path=/swagger-ui.html
springdoc.swagger-ui.operationsSorter=method

# ============================================
# ACTUATOR CONFIGURATION
# ============================================
management.endpoints.web.exposure.include=health,info,metrics
management.endpoint.health.show-details=when_authorized

# ============================================
# LOGGING CONFIGURATION
# ============================================
logging.level.root=INFO
logging.level.com.tramdoc=INFO
logging.level.org.springframework.security=WARN
```

### 4.4. Cập nhật `pom.xml`

Đảm bảo `pom.xml` có các cấu hình sau:

```xml
<properties>
    <java.version>17</java.version>
</properties>

<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
            <configuration>
                <excludes>
                    <exclude>
                        <groupId>org.projectlombok</groupId>
                        <artifactId>lombok</artifactId>
                    </exclude>
                </excludes>
            </configuration>
        </plugin>
    </plugins>
</build>
```

---

## 5. Tạo App trên Heroku

### 5.1. Khởi tạo Git repository (nếu chưa có)

```bash
cd "c:\Users\xuang\OneDrive - Dai Nam University\Backend"
git init
git add .
git commit -m "Initial commit - Tram Doc API"
```

### 5.2. Tạo Heroku App

```bash
# Tạo app với tên tự động
heroku create

# HOẶC tạo app với tên cụ thể
heroku create tram-doc-api
```

> **Lưu ý**: Tên app phải unique trên toàn bộ Heroku

### 5.3. Kiểm tra remote

```bash
git remote -v
# Output:
# heroku  https://git.heroku.com/tram-doc-api.git (fetch)
# heroku  https://git.heroku.com/tram-doc-api.git (push)
```

---

## 6. Cấu Hình Database MySQL

### 6.1. Thêm ClearDB MySQL Add-on

Heroku sử dụng ClearDB cho MySQL:

```bash
# Thêm ClearDB (có plan miễn phí ignite)
heroku addons:create cleardb:ignite
```

### 6.2. Lấy Database URL

```bash
heroku config:get CLEARDB_DATABASE_URL
# Output: mysql://username:password@host/database?reconnect=true
```

### 6.3. Cấu hình biến môi trường

```bash
# Lấy URL từ CLEARDB và parse
heroku config:get CLEARDB_DATABASE_URL

# Giả sử URL là: mysql://b1234567890abc:def12345@us-cdbr-east-06.cleardb.net/heroku_abc123?reconnect=true

# Set các biến môi trường
heroku config:set JDBC_DATABASE_URL="jdbc:mysql://us-cdbr-east-06.cleardb.net/heroku_abc123?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true&reconnect=true"
heroku config:set JDBC_DATABASE_USERNAME="b1234567890abc"
heroku config:set JDBC_DATABASE_PASSWORD="def12345"
```

### 6.4. Cấu hình JWT Secret (quan trọng!)

```bash
# Tạo secret key mạnh cho production
heroku config:set JWT_SECRET="YourSuperSecretKeyForProductionAtLeast256BitsLong_ChangeThisToSomethingUnique123456789"
```

### 6.5. (Tùy chọn) Thêm Google Books API Key

```bash
heroku config:set GOOGLE_BOOKS_API_KEY="your-google-api-key"
```

### 6.6. Kiểm tra tất cả config

```bash
heroku config
```

---

## 7. Deploy Ứng Dụng

### 7.1. Build và Deploy

```bash
# Commit tất cả thay đổi
git add .
git commit -m "Configure for Heroku deployment"

# Deploy lên Heroku
git push heroku main
# HOẶC nếu branch là master
git push heroku master
```

### 7.2. Theo dõi quá trình build

```bash
heroku logs --tail
```

### 7.3. Mở ứng dụng

```bash
heroku open
```

URL của bạn sẽ có dạng: `https://tram-doc-api.herokuapp.com`

---

## 8. Kiểm Tra và Xử Lý Lỗi

### 8.1. Kiểm tra logs

```bash
# Xem logs real-time
heroku logs --tail

# Xem 100 dòng log gần nhất
heroku logs -n 100
```

### 8.2. Kiểm tra trạng thái app

```bash
heroku ps
```

### 8.3. Restart app

```bash
heroku restart
```

### 8.4. Truy cập console

```bash
heroku run bash
```

### 8.5. Các lỗi thường gặp

#### Lỗi: "No web processes running"
```bash
heroku ps:scale web=1
```

#### Lỗi: Database connection
- Kiểm tra lại JDBC_DATABASE_URL
- Đảm bảo đã add ClearDB add-on

#### Lỗi: Port binding
- Đảm bảo đã dùng `${PORT:8080}` trong config

#### Lỗi: Build failed
```bash
# Thử build local trước
mvn clean package -DskipTests

# Nếu OK, push lại
git push heroku main
```

---

## 9. Các Lệnh Heroku Thường Dùng

```bash
# === APP MANAGEMENT ===
heroku apps                     # Liệt kê tất cả apps
heroku apps:info                # Thông tin app hiện tại
heroku apps:rename new-name     # Đổi tên app

# === LOGS ===
heroku logs --tail              # Xem logs real-time
heroku logs -n 200              # Xem 200 dòng log gần nhất

# === CONFIG ===
heroku config                   # Xem tất cả config vars
heroku config:set KEY=VALUE     # Set config var
heroku config:unset KEY         # Xóa config var

# === PROCESS ===
heroku ps                       # Xem trạng thái processes
heroku ps:scale web=1           # Scale web dyno
heroku restart                  # Restart app

# === DATABASE ===
heroku addons                   # Liệt kê add-ons
heroku pg:info                  # Thông tin PostgreSQL (nếu dùng)

# === DEPLOYMENT ===
git push heroku main            # Deploy
heroku releases                 # Xem lịch sử deploy
heroku rollback                 # Rollback về version trước
```

---

## 📝 Checklist Deploy

- [ ] Cài đặt Heroku CLI
- [ ] Đăng nhập Heroku (`heroku login`)
- [ ] Tạo file `system.properties`
- [ ] Tạo file `Procfile`
- [ ] Cập nhật `application.properties`
- [ ] Khởi tạo Git và commit
- [ ] Tạo Heroku app (`heroku create`)
- [ ] Thêm ClearDB add-on
- [ ] Cấu hình biến môi trường
- [ ] Deploy (`git push heroku main`)
- [ ] Kiểm tra logs
- [ ] Test các API endpoints

---

## 🔗 URLs Sau Khi Deploy

| URL | Mô tả |
|-----|-------|
| `https://your-app.herokuapp.com` | API Server |
| `https://your-app.herokuapp.com/swagger-ui/index.html` | Swagger UI |
| `https://your-app.herokuapp.com/api-docs` | OpenAPI Docs |
| `https://your-app.herokuapp.com/actuator/health` | Health Check |

---

## 💡 Tips

1. **Miễn phí**: Heroku có plan miễn phí nhưng app sẽ "ngủ" sau 30 phút không hoạt động
2. **Custom Domain**: Có thể thêm domain riêng trong Dashboard
3. **SSL**: Heroku cung cấp SSL miễn phí
4. **CI/CD**: Có thể kết nối GitHub để tự động deploy

---

## 🆘 Hỗ Trợ

- Heroku Documentation: https://devcenter.heroku.com/
- Heroku Status: https://status.heroku.com/
- Spring Boot on Heroku: https://devcenter.heroku.com/articles/deploying-spring-boot-apps-to-heroku

---

**Chúc bạn deploy thành công! 🚀**
