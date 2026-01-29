# 🚀 Hướng Dẫn Deploy Trạm Đọc API lên Render.com - Từng Bước

## 📋 Checklist Trước Khi Deploy

- [x] Code đã push lên GitHub
- [x] PostgreSQL driver đã có trong `pom.xml`
- [x] Dockerfile đã tạo
- [x] Spring Profiles đã cấu hình
- [ ] Render account đã tạo
- [ ] PostgreSQL database đã tạo trên Render

---

## 🎯 BƯỚC 1: Đăng Ký Render.com

1. Truy cập: **https://render.com/**
2. Click **"Get Started for Free"**
3. Đăng ký bằng **GitHub** (khuyến khích) hoặc Email
4. Xác nhận email

---

## 🗄️ BƯỚC 2: Tạo PostgreSQL Database

### 2.1. Tạo Database Instance

1. Vào **Dashboard**: https://dashboard.render.com/
2. Click **"New +"** → **"PostgreSQL"**
3. Điền thông tin:

| Trường | Giá trị |
|--------|---------|
| **Name** | `tram-doc-db` |
| **Database** | `tram_doc_db` |
| **User** | `tram_doc_user` |
| **Region** | `Singapore` (gần Việt Nam nhất) |
| **Plan** | **Free** (90 ngày) |

4. Click **"Create Database"**
5. Đợi 2-3 phút để database được tạo

### 2.2. Lấy Connection Info

Sau khi tạo xong, vào tab **"Info"**:

**Internal Database URL:**
```
postgresql:/  tram_doc_user:password123@dpg-xxx-xxx.singapore-postgres.render.com/tram_doc_db
```

**Lưu ý:** 
- URL này dùng cho **Internal** (giữa các service trong Render)
- Cần chuyển thành **JDBC URL** cho Spring Boot

---

## 🌐 BƯỚC 3: Tạo Web Service

### 3.1. Tạo Service

1. Click **"New +"** → **"Web Service"**
2. Chọn **"Build and deploy from a Git repository"**
3. **Connect GitHub** (nếu chưa)
4. Chọn repository: **`Reading-Station-API`**

### 3.2. Cấu Hình Build

| Trường | Giá trị |
|--------|---------|
| **Name** | `tram-doc-api` |
| **Region** | `Singapore` |
| **Branch** | `main` |
| **Runtime** | **Docker** |
| **Instance Type** | **Free** |

### 3.3. Environment Variables

Trong phần **"Environment"**, thêm các biến sau:

#### Database Configuration:
```
DATABASE_URL=jdbc:postgresql://dpg-xxx-xxx.singapore-postgres.render.com/tram_doc_db
DATABASE_USERNAME=tram_doc_user
DATABASE_PASSWORD=<password từ Render>
```

**⚠️ QUAN TRỌNG:** 
- Thêm `jdbc:` vào đầu URL từ Render
- Lấy password từ tab **"Info"** của PostgreSQL

#### Application Configuration:
```
SPRING_PROFILE=postgres
DDL_AUTO=update
FLYWAY_ENABLED=false
JWT_SECRET=<tạo secret key dài ít nhất 256 bits>
CORS_ORIGINS=*
```

#### Tạo JWT Secret:
```powershell
# PowerShell
-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 64 | ForEach-Object {[char]$_})
```

Hoặc dùng online: https://www.random.org/strings/

---

## 🔧 BƯỚC 4: Cấu Hình Chi Tiết

### 4.1. Parse Database URL

Render cung cấp URL dạng:
```
postgresql://user:password@host:port/database
```

Bạn cần chuyển thành:
```
jdbc:postgresql://host:port/database
```

**Ví dụ:**
```
# Render URL:
postgresql://tram_doc_user:abc123@dpg-xxx.singapore-postgres.render.com:5432/tram_doc_db

# JDBC URL (cho Spring Boot):
jdbc:postgresql://dpg-xxx.singapore-postgres.render.com:5432/tram_doc_db

# Username riêng:
tram_doc_user

# Password riêng:
abc123
```

### 4.2. Environment Variables Hoàn Chỉnh

Copy và paste vào Render (thay giá trị thực tế):

```
DATABASE_URL=jdbc:postgresql://dpg-xxx.singapore-postgres.render.com:5432/tram_doc_db
DATABASE_USERNAME=tram_doc_user
DATABASE_PASSWORD=your_actual_password
SPRING_PROFILE=postgres
DDL_AUTO=update
FLYWAY_ENABLED=false
JWT_SECRET=YourSuperSecretKeyAtLeast256BitsLong_ChangeThisToSomethingUnique123456789
CORS_ORIGINS=*
LOG_LEVEL=INFO
LOG_LEVEL_APP=INFO
```

---

## 🚀 BƯỚC 5: Deploy

1. Click **"Create Web Service"**
2. Render sẽ:
   - Clone code từ GitHub
   - Build Docker image
   - Deploy service
3. Đợi **5-10 phút** cho lần đầu

### 5.1. Theo Dõi Build

- Vào tab **"Events"** để xem log build
- Vào tab **"Logs"** để xem runtime logs

### 5.2. Kiểm Tra Deploy

Khi thấy:
```
Started TramDocApplication in X.XXX seconds
```

→ Deploy thành công! ✅

---

## ✅ BƯỚC 6: Test API

### 6.1. URLs Sau Khi Deploy

| URL | Mô tả |
|-----|-------|
| `https://tram-doc-api.onrender.com` | API Server |
| `https://tram-doc-api.onrender.com/swagger-ui.html` | Swagger UI |
| `https://tram-doc-api.onrender.com/actuator/health` | Health Check |

### 6.2. Test Health Check

```bash
curl https://tram-doc-api.onrender.com/actuator/health
```

**Expected:**
```json
{"status":"UP"}
```

### 6.3. Test Register

```bash
curl -X POST https://tram-doc-api.onrender.com/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email":"test@example.com",
    "password":"password123",
    "fullName":"Test User"
  }'
```

---

## 🔍 Xử Lý Lỗi

### Lỗi: "Database connection failed"

**Nguyên nhân:** 
- URL sai format
- Username/password sai
- Database chưa sẵn sàng

**Giải pháp:**
1. Kiểm tra lại `DATABASE_URL` đã có `jdbc:` chưa
2. Kiểm tra username/password từ Render
3. Đợi thêm 1-2 phút nếu database vừa tạo

### Lỗi: "Build failed"

**Nguyên nhân:**
- Dockerfile lỗi
- Maven build fail

**Giải pháp:**
1. Xem logs trong tab **"Events"**
2. Test build local: `mvn clean package -DskipTests`
3. Kiểm tra Dockerfile

### Lỗi: "App crash after deploy"

**Nguyên nhân:**
- Thiếu environment variables
- Database connection error

**Giải pháp:**
1. Xem logs trong tab **"Logs"**
2. Kiểm tra tất cả environment variables
3. Test database connection

---

## 📊 Monitoring

### Xem Logs

1. Vào Web Service
2. Tab **"Logs"**
3. Xem real-time logs

### Health Check

Render tự động check:
- Path: `/actuator/health`
- Interval: 30 giây

---

## ⚠️ Lưu Ý Free Tier

### Web Service:
- ⏰ **Sleep sau 15 phút** không hoạt động
- 🐌 **Cold start** mất ~30 giây
- ⏱️ **750 giờ/tháng** miễn phí

### PostgreSQL:
- ⏰ **Miễn phí 90 ngày**
- 💾 **256MB RAM**, 1GB storage
- 🔄 Sau 90 ngày cần tạo mới hoặc upgrade

### Giữ App "Thức":

Dùng cron job ping mỗi 10 phút:
- https://cron-job.org/ (miễn phí)
- https://uptimerobot.com/ (miễn phí)

**Setup:**
```
URL: https://tram-doc-api.onrender.com/actuator/health
Interval: 10 minutes
```

---

## 🎉 Hoàn Thành!

Sau khi deploy thành công:

1. ✅ Test tất cả APIs
2. ✅ Cập nhật frontend với URL mới
3. ✅ Setup cron job để giữ app "thức"
4. ✅ Monitor logs định kỳ

---

**Chúc bạn deploy thành công! 🚀**
