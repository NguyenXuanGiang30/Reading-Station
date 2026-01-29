# 🚀 Hướng Dẫn Deploy Trạm Đọc Backend lên Windows Server 2019 VPS

> **Tài liệu này hướng dẫn chi tiết cách deploy Spring Boot application lên Windows Server 2019 VPS**

---

## 📋 Yêu Cầu Hệ Thống

| Thành phần | Yêu cầu tối thiểu | Khuyến nghị |
|------------|-------------------|-------------|
| **RAM** | 2GB | 4GB+ |
| **CPU** | 1 vCPU | 2+ vCPU |
| **Disk** | 20GB | 50GB+ SSD |
| **OS** | Windows Server 2019 | - |
| **Java** | JDK 17 | JDK 17 LTS |
| **Database** | MySQL 8.0+ | MySQL 8.0+ |

---

## 📦 Phần 1: Cài Đặt Phần Mềm Cần Thiết

### 1.1. Cài đặt Java JDK 17

1. **Tải JDK 17** từ [Adoptium (Eclipse Temurin)](https://adoptium.net/temurin/releases/?version=17)
   - Chọn: **Windows x64** → **JDK** → **.msi**

2. **Chạy file .msi** và làm theo hướng dẫn cài đặt

3. **Cấu hình Environment Variables:**
   - Mở **System Properties** → **Advanced** → **Environment Variables**
   - Thêm **JAVA_HOME**: `C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot`
   - Thêm vào **Path**: `%JAVA_HOME%\bin`

4. **Kiểm tra cài đặt:**
   ```powershell
   java -version
   # Output: openjdk version "17.x.x"
   ```

### 1.2. Cài đặt MySQL 8.0

1. **Tải MySQL Installer** từ [MySQL Downloads](https://dev.mysql.com/downloads/installer/)
   - Chọn: **mysql-installer-community-8.x.x.msi**

2. **Chạy installer** và chọn:
   - **Setup Type**: Server only (hoặc Custom nếu cần thêm tools)
   - **Root Password**: Đặt password mạnh và **ghi nhớ lại**
   - **Windows Service**: ✅ Configure MySQL Server as a Windows Service

3. **Tạo Database:**
   ```sql
   -- Mở MySQL Command Line Client hoặc MySQL Workbench
   CREATE DATABASE tram_doc_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   
   -- Tạo user riêng cho app (khuyến nghị)
   CREATE USER 'tramdoc_user'@'localhost' IDENTIFIED BY 'your_secure_password';
   GRANT ALL PRIVILEGES ON tram_doc_db.* TO 'tramdoc_user'@'localhost';
   FLUSH PRIVILEGES;
   ```

4. **Kiểm tra MySQL Service:**
   ```powershell
   Get-Service -Name "MySQL*"
   # Status phải là Running
   ```

### 1.3. Cài đặt Maven (Tùy chọn - để build từ source)

1. **Tải Maven** từ [Apache Maven](https://maven.apache.org/download.cgi)
   - Chọn: **apache-maven-3.9.x-bin.zip**

2. **Giải nén** vào `C:\Program Files\Apache\maven`

3. **Cấu hình Environment Variables:**
   - Thêm **M2_HOME**: `C:\Program Files\Apache\maven`
   - Thêm vào **Path**: `%M2_HOME%\bin`

4. **Kiểm tra:**
   ```powershell
   mvn -version
   ```

---

## 📁 Phần 2: Chuẩn Bị Project

### 2.1. Cấu trúc thư mục trên VPS

Tạo cấu trúc thư mục như sau:

```
C:\Apps\
└── TramdocAPI\
    ├── app\                    # Thư mục chứa JAR file
    │   └── tram-doc-backend.jar
    ├── config\                 # Thư mục chứa config
    │   └── application-prod.properties
    ├── logs\                   # Thư mục lưu log
    ├── scripts\                # Scripts khởi động/dừng
    │   ├── start-api.bat
    │   ├── stop-api.bat
    │   └── install-service.bat
    └── uploads\                # Thư mục lưu file upload
```

**Tạo thư mục bằng PowerShell:**
```powershell
New-Item -ItemType Directory -Force -Path "C:\Apps\TramdocAPI\app"
New-Item -ItemType Directory -Force -Path "C:\Apps\TramdocAPI\config"
New-Item -ItemType Directory -Force -Path "C:\Apps\TramdocAPI\logs"
New-Item -ItemType Directory -Force -Path "C:\Apps\TramdocAPI\scripts"
New-Item -ItemType Directory -Force -Path "C:\Apps\TramdocAPI\uploads"
```

### 2.2. Build JAR file (trên máy local)

Trên máy phát triển, chạy lệnh sau để build:

```powershell
# Di chuyển đến thư mục project
cd "c:\Users\xuang\OneDrive - Dai Nam University\Backend"

# Build JAR (skip tests để build nhanh hơn)
mvn clean package -DskipTests

# File JAR sẽ được tạo tại:
# target\tram-doc-backend-1.0.0.jar
```

### 2.3. Copy files lên VPS

**Cách 1: Remote Desktop (RDP)**
- Kết nối RDP đến VPS
- Copy file `target\tram-doc-backend-1.0.0.jar` vào `C:\Apps\TramdocAPI\app\`

**Cách 2: SCP/SFTP**
```powershell
# Sử dụng scp (nếu có OpenSSH trên VPS)
scp target\tram-doc-backend-1.0.0.jar administrator@your-vps-ip:C:\Apps\TramdocAPI\app\
```

---

## ⚙️ Phần 3: Cấu Hình Production

### 3.1. Tạo file cấu hình Production

Tạo file `C:\Apps\TramdocAPI\config\application-prod.properties`:

```properties
# ============================================
# PRODUCTION CONFIGURATION
# ============================================
server.port=8080
spring.profiles.active=mysql

# ============================================
# DATABASE CONFIGURATION
# ============================================
spring.datasource.url=jdbc:mysql://localhost:3306/tram_doc_db?createDatabaseIfNotExist=true&useSSL=false&serverTimezone=Asia/Ho_Chi_Minh&allowPublicKeyRetrieval=true
spring.datasource.username=tramdoc_user
spring.datasource.password=your_secure_password
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

# ============================================
# JPA/HIBERNATE
# ============================================
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false

# ============================================
# JWT CONFIGURATION (QUAN TRỌNG: ĐỔI SECRET KEY!)
# ============================================
# Tạo secret key mới: https://generate-secret.vercel.app/64
jwt.secret=YOUR_PRODUCTION_SECRET_KEY_MIN_64_CHARACTERS_CHANGE_THIS_NOW_PLEASE
jwt.expiration=86400000
jwt.refresh-expiration=604800000

# ============================================
# CORS - Thêm domain frontend của bạn
# ============================================
cors.allowed-origins=http://localhost:3000,https://your-frontend-domain.com

# ============================================
# LOGGING
# ============================================
logging.level.root=WARN
logging.level.com.tramdoc=INFO
logging.file.name=C:/Apps/TramdocAPI/logs/tramdoc-api.log
logging.logback.rollingpolicy.max-file-size=10MB
logging.logback.rollingpolicy.max-history=30

# ============================================
# ACTUATOR (Health check)
# ============================================
management.endpoints.web.exposure.include=health,info
management.endpoint.health.show-details=never
```

> ⚠️ **QUAN TRỌNG:** 
> - Thay `your_secure_password` bằng password MySQL thực
> - Thay `YOUR_PRODUCTION_SECRET_KEY_...` bằng secret key mới (tối thiểu 64 ký tự)
> - Cập nhật `cors.allowed-origins` với domain frontend thực

---

## 🎬 Phần 4: Scripts Khởi Động

### 4.1. Script khởi động (start-api.bat)

Tạo file `C:\Apps\TramdocAPI\scripts\start-api.bat`:

```batch
@echo off
TITLE Tram Doc API Server

:: Cấu hình
SET APP_NAME=Tram Doc API
SET APP_HOME=C:\Apps\TramdocAPI
SET JAR_FILE=%APP_HOME%\app\tram-doc-backend-1.0.0.jar
SET CONFIG_FILE=%APP_HOME%\config\application-prod.properties
SET LOG_FILE=%APP_HOME%\logs\console.log
SET PID_FILE=%APP_HOME%\app\app.pid

:: Kiểm tra Java
java -version >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Java khong duoc cai dat hoac khong co trong PATH
    pause
    exit /b 1
)

:: Kiểm tra JAR file
IF NOT EXIST "%JAR_FILE%" (
    echo [ERROR] Khong tim thay JAR file: %JAR_FILE%
    pause
    exit /b 1
)

echo ============================================
echo Starting %APP_NAME%...
echo ============================================
echo JAR: %JAR_FILE%
echo Config: %CONFIG_FILE%
echo Log: %LOG_FILE%
echo ============================================

:: Khởi động ứng dụng
cd /d %APP_HOME%
java -Xms256m -Xmx512m ^
     -Dspring.config.location=file:%CONFIG_FILE% ^
     -Dfile.encoding=UTF-8 ^
     -jar "%JAR_FILE%" > "%LOG_FILE%" 2>&1

pause
```

### 4.2. Script dừng (stop-api.bat)

Tạo file `C:\Apps\TramdocAPI\scripts\stop-api.bat`:

```batch
@echo off
TITLE Stop Tram Doc API

echo ============================================
echo Stopping Tram Doc API...
echo ============================================

:: Tìm và kill process Java đang chạy JAR file
FOR /F "tokens=2" %%p IN ('wmic process where "commandline like '%%tram-doc-backend%%'" get processid 2^>nul ^| findstr /r "[0-9]"') DO (
    echo Stopping process ID: %%p
    taskkill /F /PID %%p
)

echo.
echo API Server da dung!
pause
```

### 4.3. Script chạy nền (start-background.bat)

Tạo file `C:\Apps\TramdocAPI\scripts\start-background.bat`:

```batch
@echo off
:: Chạy API ở chế độ nền

SET APP_HOME=C:\Apps\TramdocAPI
SET JAR_FILE=%APP_HOME%\app\tram-doc-backend-1.0.0.jar
SET CONFIG_FILE=%APP_HOME%\config\application-prod.properties
SET LOG_FILE=%APP_HOME%\logs\console.log

cd /d %APP_HOME%

:: Sử dụng "start" để chạy trong cửa sổ mới, minimized
start /min "TramdocAPI" java -Xms256m -Xmx512m ^
     -Dspring.config.location=file:%CONFIG_FILE% ^
     -Dfile.encoding=UTF-8 ^
     -jar "%JAR_FILE%" > "%LOG_FILE%" 2>&1

echo API Server dang khoi dong o che do nen...
echo Kiem tra log tai: %LOG_FILE%
```

---

## 🔧 Phần 5: Cài Đặt Như Windows Service (Khuyến Nghị)

### 5.1. Sử dụng NSSM (Non-Sucking Service Manager)

**Tải NSSM:**
- Truy cập: https://nssm.cc/download
- Tải bản mới nhất và giải nén vào `C:\Tools\nssm`

**Cài đặt Service:**

```powershell
# Mở PowerShell với quyền Administrator

# Di chuyển đến thư mục NSSM
cd C:\Tools\nssm\win64

# Cài đặt service
.\nssm.exe install TramdocAPI

# Cửa sổ GUI sẽ mở ra, điền các thông tin:
# Path: C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot\bin\java.exe
# Startup directory: C:\Apps\TramdocAPI
# Arguments: -Xms256m -Xmx512m -Dspring.config.location=file:C:\Apps\TramdocAPI\config\application-prod.properties -Dfile.encoding=UTF-8 -jar C:\Apps\TramdocAPI\app\tram-doc-backend-1.0.0.jar

# Tab Details:
# Display name: Tram Doc API Server
# Description: Backend API for Tram Doc Reading Station Application
# Startup type: Automatic

# Tab I/O:
# Output (stdout): C:\Apps\TramdocAPI\logs\service-stdout.log
# Error (stderr): C:\Apps\TramdocAPI\logs\service-stderr.log

# Click "Install service"
```

**Quản lý Service:**

```powershell
# Khởi động service
Start-Service -Name "TramdocAPI"

# Kiểm tra status
Get-Service -Name "TramdocAPI"

# Dừng service
Stop-Service -Name "TramdocAPI"

# Restart service
Restart-Service -Name "TramdocAPI"

# Xóa service (nếu cần)
.\nssm.exe remove TramdocAPI confirm
```

---

## 🌐 Phần 6: Cấu Hình Firewall & Network

### 6.1. Mở Port 8080 trong Windows Firewall

```powershell
# Mở PowerShell với quyền Administrator

# Cho phép Inbound port 8080
New-NetFirewallRule -DisplayName "Tram Doc API (8080)" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 8080 `
    -Action Allow

# Kiểm tra rule đã được tạo
Get-NetFirewallRule -DisplayName "Tram Doc API*"
```

### 6.2. Cấu hình trên VPS Provider (Nếu cần)

Nếu VPS của bạn có firewall riêng (như Security Groups trên AWS, Firewall Rules trên Google Cloud, hoặc trên control panel của nhà cung cấp), hãy đảm bảo:

- **Port 8080** (hoặc port bạn chọn) được mở cho **TCP Inbound**
- **Port 3306** (MySQL) **CHỈ** mở cho localhost hoặc internal network

---

## ✅ Phần 7: Kiểm Tra Deployment

### 7.1. Kiểm tra API hoạt động

```powershell
# Kiểm tra từ localhost trên VPS
Invoke-RestMethod -Uri "http://localhost:8080/actuator/health"

# Kết quả mong đợi:
# status
# ------
# UP

# Kiểm tra Swagger UI (mở trình duyệt)
# http://localhost:8080/swagger-ui.html
```

### 7.2. Kiểm tra từ bên ngoài

```bash
# Từ máy local (thay YOUR_VPS_IP bằng IP thực)
curl http://YOUR_VPS_IP:8080/actuator/health

# Hoặc mở trình duyệt:
# http://YOUR_VPS_IP:8080/swagger-ui.html
```

### 7.3. Kiểm tra logs

```powershell
# Xem log console
Get-Content -Path "C:\Apps\TramdocAPI\logs\console.log" -Tail 50

# Xem log application
Get-Content -Path "C:\Apps\TramdocAPI\logs\tramdoc-api.log" -Tail 50

# Follow log realtime
Get-Content -Path "C:\Apps\TramdocAPI\logs\tramdoc-api.log" -Wait
```

---

## 🔒 Phần 8: Bảo Mật (Security Checklist)

### ✅ Checklist Bảo Mật

- [ ] **JWT Secret Key**: Đã thay đổi sang key mạnh (64+ ký tự)
- [ ] **Database Password**: Sử dụng password mạnh
- [ ] **Database User**: Tạo user riêng, không dùng root
- [ ] **MySQL Port**: Không expose port 3306 ra internet
- [ ] **Windows Updates**: Cài đặt các bản cập nhật bảo mật
- [ ] **Windows Firewall**: Chỉ mở các port cần thiết
- [ ] **RDP**: Đổi port RDP mặc định (3389) hoặc sử dụng VPN
- [ ] **HTTPS**: Cân nhắc sử dụng reverse proxy (IIS/Nginx) với SSL

### 8.1. Sử dụng IIS làm Reverse Proxy (Optional)

Nếu bạn muốn sử dụng HTTPS, có thể setup IIS làm reverse proxy:

1. Cài đặt **IIS** với **ARR (Application Request Routing)**
2. Cài đặt **URL Rewrite Module**
3. Cấu hình reverse proxy từ port 443 → localhost:8080
4. Cài đặt SSL Certificate (Let's Encrypt hoặc certificate khác)

---

## 🛠️ Phần 9: Troubleshooting

### Lỗi thường gặp và cách xử lý

| Lỗi | Nguyên nhân | Giải pháp |
|-----|-------------|-----------|
| `Port 8080 already in use` | Port đang bị chiếm | `netstat -ano \| findstr :8080` và kill process |
| `Access denied connecting to MySQL` | Sai username/password | Kiểm tra lại credentials trong config |
| `java.lang.OutOfMemoryError` | Thiếu RAM | Tăng `-Xmx` hoặc nâng cấp VPS |
| `Connection refused` | Firewall chặn | Kiểm tra Windows Firewall và VPS firewall |
| `Table doesn't exist` | DB chưa được migrate | Đảm bảo `ddl-auto=update` trong config |

### Kiểm tra process Java

```powershell
# Liệt kê tất cả process Java
Get-Process java

# Xem chi tiết process theo port
netstat -ano | findstr :8080
```

### Restart toàn bộ

```powershell
# Dừng service
Stop-Service -Name "TramdocAPI"

# Đợi 5 giây
Start-Sleep -Seconds 5

# Khởi động lại
Start-Service -Name "TramdocAPI"

# Kiểm tra status
Get-Service -Name "TramdocAPI"
```

---

## 📝 Tóm Tắt Các Bước Deploy

```
1. ✅ Cài đặt JDK 17
2. ✅ Cài đặt MySQL 8.0
3. ✅ Tạo database và user MySQL
4. ✅ Tạo cấu trúc thư mục
5. ✅ Build JAR file trên máy local
6. ✅ Copy JAR lên VPS
7. ✅ Tạo file cấu hình production
8. ✅ Cài đặt Windows Service (NSSM)
9. ✅ Cấu hình Firewall
10. ✅ Kiểm tra API hoạt động
```

---

## 📞 Hỗ Trợ

Nếu gặp vấn đề khi deploy, kiểm tra:
1. **Logs**: `C:\Apps\TramdocAPI\logs\`
2. **Event Viewer**: Windows Logs → Application
3. **Service Status**: `Get-Service -Name "TramdocAPI"`

---

**Version:** 1.0.0  
**Last Updated:** January 27, 2026  
**Author:** Trạm Đọc Backend Team
