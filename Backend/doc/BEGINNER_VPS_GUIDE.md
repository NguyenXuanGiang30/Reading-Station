# 🎯 Hướng Dẫn Deploy Backend Cho Người Mới Bắt Đầu

> **Dành cho người lần đầu sử dụng VPS Windows Server 2019**

---

## 🖥️ Quy Ước Màu Sắc

Trong tài liệu này, mỗi bước sẽ được đánh dấu rõ ràng thực hiện ở đâu:

| Biểu tượng | Ý nghĩa |
|------------|---------|
| 💻 **[MÁY DEV]** | Thực hiện trên **máy tính của bạn** (laptop/PC cá nhân) |
| 🌐 **[VPS]** | Thực hiện trên **VPS Windows Server** |
| 🔄 **[CẢ HAI]** | Có thể thực hiện ở cả hai nơi |

---

## 📑 Tổng Quan Các Bước

| STT | Bước | Nơi thực hiện |
|-----|------|---------------|
| 1 | Kết nối vào VPS | 💻 MÁY DEV |
| 2 | Cài đặt Java JDK 17 | 🌐 VPS |
| 3 | Cài đặt MySQL 8.0 | 🌐 VPS |
| 4 | Tạo Database | 🌐 VPS |
| 5 | Chuẩn bị thư mục | 🌐 VPS |
| 6 | Build JAR file | 💻 MÁY DEV |
| 7 | Copy files lên VPS | 💻 MÁY DEV → 🌐 VPS |
| 8 | Cấu hình Production | 🌐 VPS |
| 9 | Chạy thử API | 🌐 VPS |
| 10 | Cài đặt Windows Service | 🌐 VPS |
| 11 | Mở Firewall | 🌐 VPS |
| 12 | Kiểm tra từ bên ngoài | 💻 MÁY DEV |

---

# 💻 [MÁY DEV] Bước 1: Kết Nối Vào VPS

> ⚡ **Thực hiện trên: MÁY TÍNH CỦA BẠN**

### 1.1. Thông tin bạn cần có từ nhà cung cấp VPS

Khi mua VPS, bạn sẽ nhận được email chứa:
- **IP Address**: Ví dụ: `103.123.45.67`
- **Username**: Thường là `Administrator`
- **Password**: Mật khẩu đăng nhập

### 1.2. Kết nối bằng Remote Desktop (RDP)

**Trên máy Windows của bạn:**

1. Nhấn phím **Windows + R** để mở hộp thoại Run

2. Gõ `mstsc` rồi nhấn **Enter**

3. Cửa sổ **Remote Desktop Connection** sẽ mở ra

4. Trong ô **Computer**, nhập **IP Address** của VPS (ví dụ: `103.123.45.67`)

5. Click **Connect**

6. Khi được hỏi username/password:
   - **Username**: `Administrator` (hoặc username được cấp)
   - **Password**: Password trong email từ nhà cung cấp

7. Nếu có cảnh báo certificate, click **Yes** để tiếp tục

8. ✅ **Thành công**: Bạn sẽ thấy màn hình Desktop của Windows Server

> 📝 **Tip**: Sau khi kết nối, bạn đang "ngồi trước" VPS như đang dùng máy tính thực. Tất cả các bước từ 2-11 sẽ thực hiện trong cửa sổ Remote Desktop này.

---

# 🌐 [VPS] Bước 2: Cài Đặt Java JDK 17

> ⚡ **Thực hiện trên: VPS (trong cửa sổ Remote Desktop)**

### 2.1. Tải Java JDK 17

1. **Trong cửa sổ Remote Desktop (VPS)**, mở **Microsoft Edge**
   - Click vào icon Edge trên taskbar hoặc tìm trong Start menu

2. Truy cập: https://adoptium.net/temurin/releases/?version=17

3. Chọn các tùy chọn (trên website):
   - **Operating System**: Windows
   - **Architecture**: x64
   - **Package Type**: JDK
   
4. Click nút **Download .msi** (tải file installer)

### 2.2. Cài đặt Java

1. Mở thư mục **Downloads** trên VPS:
   - Mở File Explorer → Downloads

2. Double-click file `.msi` vừa tải

3. Trong cửa sổ cài đặt:
   - Click **Next**
   - Tại màn hình features, **đánh dấu các ô sau**:
     - ✅ Add to PATH
     - ✅ Set JAVA_HOME variable
   - Click **Next** → **Install**

4. Nếu có popup UAC (User Account Control), click **Yes**

5. Đợi cài đặt hoàn tất → Click **Finish**

### 2.3. Kiểm tra Java đã cài đặt

1. **Trên VPS**, click chuột phải vào nút **Start** (góc trái dưới)

2. Chọn **Windows PowerShell**

3. Gõ lệnh (rồi nhấn Enter):
   ```powershell
   java -version
   ```

4. ✅ **Nếu thành công**, bạn sẽ thấy:
   ```
   openjdk version "17.0.x" 2024-xx-xx
   OpenJDK Runtime Environment Temurin-17.0.x+x (build 17.0.x+x)
   OpenJDK 64-Bit Server VM Temurin-17.0.x+x (build 17.0.x+x, mixed mode)
   ```

> ⚠️ **Nếu báo lỗi "java is not recognized"**:
> - Khởi động lại VPS (Start → Power → Restart)
> - Sau khi khởi động lại, kết nối Remote Desktop lại và thử lệnh `java -version`

---

# 🌐 [VPS] Bước 3: Cài Đặt MySQL 8.0

> ⚡ **Thực hiện trên: VPS (trong cửa sổ Remote Desktop)**

### 3.1. Tải MySQL Installer

1. **Trên VPS**, mở trình duyệt Edge

2. Truy cập: https://dev.mysql.com/downloads/installer/

3. Tìm và click vào bản **Windows (x86, 32-bit), MSI Installer** 
   - Chọn bản **Full** (khoảng 300MB), không phải bản web

4. Ở trang tiếp theo, click **"No thanks, just start my download"** (bên dưới nút Login)

5. Đợi tải xong (có thể mất 5-10 phút tùy tốc độ mạng)

### 3.2. Cài đặt MySQL

1. Mở file `.msi` từ thư mục Downloads

2. **Choosing a Setup Type**: 
   - Chọn **Server only** 
   - Click **Next**

3. **Check Requirements**: Click **Execute** (nếu có) → **Next**

4. **Installation**: Click **Execute** để cài đặt → Đợi hoàn tất → **Next**

5. **Product Configuration**: Click **Next**

6. **Type and Networking**:
   - Config Type: **Development Computer**
   - Port: **3306** (giữ nguyên)
   - Click **Next**

7. **Authentication Method**:
   - Chọn **Use Strong Password Encryption for Authentication (RECOMMENDED)**
   - Click **Next**

8. **Accounts and Roles** ⚠️ **QUAN TRỌNG**:
   - **MySQL Root Password**: Nhập password và **GHI LẠI NGAY!**
   - Ví dụ: `MyStr0ngP@ss2024!`
   - **Repeat Password**: Nhập lại password
   - Click **Next**

   ```
   📝 GHI LẠI NGAY:
   MySQL Root Password: giang2005
   ```

9. **Windows Service**:
   - ✅ Configure MySQL Server as a Windows Service
   - Windows Service Name: `MySQL80` (giữ nguyên)
   - ✅ Start the MySQL Server at System Startup
   - Click **Next**

10. **Server File Permissions**: Giữ mặc định → **Next**

11. **Apply Configuration**: Click **Execute**
    - Đợi tất cả các bước có dấu ✅
    - Click **Finish**

12. **Product Configuration**: Click **Next** → **Finish**

### 3.3. Kiểm tra MySQL đang chạy

1. **Trên VPS**, mở **PowerShell**

2. Chạy lệnh:
   ```powershell
   Get-Service -Name "MySQL*"
   ```

3. ✅ Kết quả phải hiển thị **Status: Running**:
   ```
   Status   Name               DisplayName
   ------   ----               -----------
   Running  MySQL80            MySQL80
   ```

---

# 🌐 [VPS] Bước 4: Tạo Database

> ⚡ **Thực hiện trên: VPS (trong cửa sổ Remote Desktop)**

### 4.1. Mở MySQL Command Line

1. **Trên VPS**, click **Start** → gõ tìm **"MySQL 8.0 Command Line Client"**

2. Click để mở

3. Nhập **root password** bạn đã tạo ở Bước 3

4. Nhấn **Enter**

5. Bạn sẽ thấy prompt: `mysql>`

### 4.2. Tạo Database

Gõ từng lệnh sau (nhấn Enter sau mỗi lệnh):

```sql
CREATE DATABASE tram_doc_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

Kết quả: `Query OK, 1 row affected`

### 4.3. Kiểm tra Database đã tạo

```sql
SHOW DATABASES;
```

Bạn sẽ thấy `tram_doc_db` trong danh sách.

### 4.4. Tạo User cho ứng dụng

**⚠️ Thay `YOUR_APP_PASSWORD` bằng password bạn muốn đặt:**

```sql
CREATE USER 'tramdoc_user'@'localhost' IDENTIFIED BY 'YOUR_APP_PASSWORD';
```

```sql
GRANT ALL PRIVILEGES ON tram_doc_db.* TO 'tramdoc_user'@'localhost';
```

```sql
FLUSH PRIVILEGES;
```

### 4.5. Thoát MySQL

```sql
EXIT;
```

### 📝 Ghi chú lại thông tin (sẽ dùng ở Bước 8):

```
Database Name: tram_doc_db
Database Username: tramdoc_user  
Database Password: giang2005 (password bạn vừa đặt)
```

---

# 🌐 [VPS] Bước 5: Chuẩn Bị Thư Mục

> ⚡ **Thực hiện trên: VPS (trong cửa sổ Remote Desktop)**

### 5.1. Tạo cấu trúc thư mục

1. **Trên VPS**, mở **PowerShell**
   - Click chuột phải Start → Windows PowerShell

2. Copy TOÀN BỘ đoạn lệnh sau và paste vào PowerShell:

```powershell
New-Item -ItemType Directory -Force -Path "C:\Apps\TramdocAPI\app"
New-Item -ItemType Directory -Force -Path "C:\Apps\TramdocAPI\config"
New-Item -ItemType Directory -Force -Path "C:\Apps\TramdocAPI\logs"
New-Item -ItemType Directory -Force -Path "C:\Apps\TramdocAPI\scripts"
```

3. Nhấn **Enter**

4. Kiểm tra thư mục đã tạo:
```powershell
Get-ChildItem "C:\Apps\TramdocAPI"
```

Kết quả hiển thị 4 thư mục: `app`, `config`, `logs`, `scripts`

### 5.2. Tải NSSM (để cài Service sau)

Copy toàn bộ đoạn lệnh sau và paste vào PowerShell:

```powershell
# Tạo thư mục Tools
New-Item -ItemType Directory -Force -Path "C:\Tools"

# Tải NSSM
Invoke-WebRequest -Uri "https://nssm.cc/release/nssm-2.24.zip" -OutFile "C:\Tools\nssm.zip"

# Giải nén
Expand-Archive -Path "C:\Tools\nssm.zip" -DestinationPath "C:\Tools" -Force

# Đổi tên thư mục
Rename-Item "C:\Tools\nssm-2.24" "C:\Tools\nssm" -ErrorAction SilentlyContinue

# Kiểm tra
Get-ChildItem "C:\Tools\nssm\win64"
```

✅ Thành công khi thấy file `nssm.exe`

---

# 💻 [MÁY DEV] Bước 6: Build JAR File

> ⚡ **Thực hiện trên: MÁY TÍNH CỦA BẠN (không phải VPS)**
> 
> ⚠️ **QUAN TRỌNG**: Bước này làm trên laptop/PC cá nhân của bạn, KHÔNG phải trong Remote Desktop!

### 6.1. Mở PowerShell trên máy của bạn

1. **Thu nhỏ cửa sổ Remote Desktop** (không đóng)

2. **Trên máy tính của bạn**, nhấn **Windows + X** → **Windows PowerShell**

### 6.2. Di chuyển đến thư mục project

```powershell
cd "c:\Users\xuang\OneDrive - Dai Nam University\Backend"
```

### 6.3. Build JAR file

```powershell
mvn clean package -DskipTests
```

> ⏳ **Thời gian**: Lần đầu có thể mất 3-10 phút để Maven tải dependencies

### 6.4. Kiểm tra file JAR đã được tạo

```powershell
Get-ChildItem target\*.jar
```

✅ Bạn sẽ thấy file: `tram-doc-backend-1.0.0.jar`

### 6.5. Ghi nhớ đường dẫn file JAR

```
C:\Users\xuang\OneDrive - Dai Nam University\Backend\target\tram-doc-backend-1.0.0.jar
```

---

# 💻➡️🌐 Bước 7: Copy Files Lên VPS

> ⚡ **Bắt đầu từ MÁY DEV, copy sang VPS**

### 7.1. Mở thư mục chứa JAR trên máy của bạn

1. **Trên máy tính của bạn** (không phải Remote Desktop)

2. Mở **File Explorer**

3. Điều hướng đến:
   ```
   c:\Users\xuang\OneDrive - Dai Nam University\Backend\target\
   ```

4. Tìm file `tram-doc-backend-1.0.0.jar`

### 7.2. Copy file sang VPS

**Cách 1: Dùng Remote Desktop (Đơn giản nhất)**

1. **Click chuột phải** vào file `tram-doc-backend-1.0.0.jar` → **Copy** (hoặc Ctrl+C)

2. **Click vào cửa sổ Remote Desktop** để chuyển sang VPS

3. **Trong VPS**, mở File Explorer

4. Điều hướng đến: `C:\Apps\TramdocAPI\app\`

5. **Paste** file (Ctrl+V)

6. ⏳ Đợi copy hoàn tất (file khoảng 50-80MB)

**Cách 2: Nếu Copy/Paste không hoạt động**

1. Đóng Remote Desktop

2. Mở lại Remote Desktop (mstsc)

3. Trước khi Connect, click **Show Options** → tab **Local Resources**

4. Click **More...** → ✅ Đánh dấu **Drives** → OK

5. Connect lại

6. Trong VPS, mở File Explorer → bạn sẽ thấy ổ đĩa máy local của bạn

7. Copy file từ đó sang `C:\Apps\TramdocAPI\app\`

### 7.3. Kiểm tra file đã copy

**Trên VPS**, mở PowerShell:

```powershell
Get-ChildItem "C:\Apps\TramdocAPI\app\"
```

✅ Phải thấy file `tram-doc-backend-1.0.0.jar`

---

# 🌐 [VPS] Bước 8: Cấu Hình Production

> ⚡ **Thực hiện trên: VPS (trong cửa sổ Remote Desktop)**

### 8.1. Tạo JWT Secret Key

1. **Trên VPS**, mở trình duyệt Edge

2. Truy cập: https://generate-secret.vercel.app/64

3. **Copy** key được hiển thị (64 ký tự)

4. **Lưu lại** key này để dùng ở bước sau:
   ```
   JWT Secret: c9090be3fb806593344893bbb370503ddbc4eb430dd76ef34772825ac94aa3ef
   ```

### 8.2. Tạo file cấu hình

1. **Trên VPS**, mở **Notepad**
   - Start → gõ "Notepad" → Enter

2. **Copy TOÀN BỘ nội dung bên dưới và paste vào Notepad**:

```properties
# ============================================
# PRODUCTION CONFIGURATION FOR TRAM DOC API
# ============================================
server.port=8080
spring.profiles.active=mysql

# ============================================
# DATABASE - THAY BANG PASSWORD CUA BAN
# ============================================
spring.datasource.url=jdbc:mysql://localhost:3306/tram_doc_db?createDatabaseIfNotExist=true&useSSL=false&serverTimezone=Asia/Ho_Chi_Minh&allowPublicKeyRetrieval=true
spring.datasource.username=tramdoc_user
spring.datasource.password=THAY_BANG_PASSWORD_DATABASE_CUA_BAN
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

# JPA
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false

# ============================================
# JWT - THAY BANG SECRET KEY DA TAO
# ============================================
jwt.secret=THAY_BANG_JWT_SECRET_64_KY_TU_DA_TAO_O_BUOC_8.1
jwt.expiration=86400000
jwt.refresh-expiration=604800000

# ============================================
# CORS
# ============================================
cors.allowed-origins=http://localhost:3000,https://your-frontend-domain.com

# ============================================
# LOGGING
# ============================================
logging.level.root=WARN
logging.level.com.tramdoc=INFO
logging.file.name=C:/Apps/TramdocAPI/logs/tramdoc-api.log

# ============================================
# ACTUATOR
# ============================================
management.endpoints.web.exposure.include=health,info
management.endpoint.health.show-details=never
```

### 8.3. Sửa các giá trị quan trọng

**⚠️ BẮT BUỘC phải sửa 2 chỗ:**

1. **Dòng `spring.datasource.password=`**
   - Thay `THAY_BANG_PASSWORD_DATABASE_CUA_BAN` bằng password bạn đã tạo ở Bước 4

2. **Dòng `jwt.secret=`**
   - Thay `THAY_BANG_JWT_SECRET_64_KY_TU_DA_TAO_O_BUOC_8.1` bằng secret key đã tạo ở Bước 8.1

### 8.4. Lưu file

1. Trong Notepad: **File** → **Save As...**

2. **Quan trọng**: 
   - Navigate đến: `C:\Apps\TramdocAPI\config\`
   - File name: `application-prod.properties`
   - Save as type: **All Files (*.*)**  ← ⚠️ QUAN TRỌNG!
   
3. Click **Save**

### 8.5. Kiểm tra file đã lưu đúng

```powershell
Get-ChildItem "C:\Apps\TramdocAPI\config\"
```

✅ Phải thấy file `application-prod.properties` (không phải `.properties.txt`)

---

# 🌐 [VPS] Bước 9: Chạy Thử API

> ⚡ **Thực hiện trên: VPS (trong cửa sổ Remote Desktop)**

### 9.1. Tìm đường dẫn Java

1. Mở PowerShell trên VPS

2. Chạy lệnh:
```powershell
Get-Command java | Select-Object Source
```

3. Ghi lại đường dẫn, ví dụ:
```
C:\Program Files\Eclipse Adoptium\jdk-17.0.13+11\bin\java.exe
```

### 9.2. Chạy API lần đầu

1. Trong PowerShell, chạy lệnh sau:

```powershell
cd C:\Apps\TramdocAPI

java -Xms256m -Xmx512m -Dspring.config.location=file:C:\Apps\TramdocAPI\config\application-prod.properties -Dfile.encoding=UTF-8 -jar C:\Apps\TramdocAPI\app\tram-doc-backend-1.0.0.jar
```

2. **Đợi 30-60 giây** để API khởi động

3. ✅ **Thành công** khi thấy dòng log:
```
Started TramDocBackendApplication in X.XXX seconds
```

### 9.3. Test API trên VPS

1. **Giữ nguyên** cửa sổ PowerShell đang chạy API

2. Mở **trình duyệt Edge** trên VPS

3. Truy cập: http://localhost:8080/actuator/health

4. ✅ Nếu thấy `{"status":"UP"}` → **API đang chạy!**

5. Thử Swagger UI: http://localhost:8080/swagger-ui.html

### 9.4. Dừng API test

1. Quay lại PowerShell đang chạy API

2. Nhấn **Ctrl + C**

3. API sẽ dừng lại

---

# 🌐 [VPS] Bước 10: Cài Đặt Windows Service

> ⚡ **Thực hiện trên: VPS (trong cửa sổ Remote Desktop)**

### 10.1. Mở PowerShell với quyền Admin

1. Click chuột phải vào **Start** (góc trái dưới)

2. Chọn **Windows PowerShell (Admin)**

3. Nếu có popup UAC, click **Yes**

### 10.2. Cài đặt Service bằng NSSM

1. Chạy lệnh:

```powershell
cd C:\Tools\nssm\win64
.\nssm.exe install TramdocAPI
```

2. **Cửa sổ NSSM sẽ mở ra**

### 10.3. Điền thông tin trong NSSM GUI

**Tab "Application":**

| Field | Giá trị |
|-------|---------|
| **Path** | `C:\Program Files\Eclipse Adoptium\jdk-17.0.13+11\bin\java.exe` |
| **Startup directory** | `C:\Apps\TramdocAPI` |
| **Arguments** | `-Xms256m -Xmx512m -Dspring.config.location=file:C:\Apps\TramdocAPI\config\application-prod.properties -Dfile.encoding=UTF-8 -jar C:\Apps\TramdocAPI\app\tram-doc-backend-1.0.0.jar` |

> ⚠️ **Lưu ý về Path**: 
> - Click nút **...** bên cạnh ô Path để browse
> - Điều hướng đến: `C:\Program Files\Eclipse Adoptium\` 
> - Tìm thư mục `jdk-17.x.x` (version có thể khác)
> - Vào thư mục `bin` → chọn `java.exe`

**Tab "Details":**

| Field | Giá trị |
|-------|---------|
| **Display name** | `Tram Doc API Server` |
| **Description** | `Backend API for Tram Doc Reading Station` |
| **Startup type** | `Automatic` |

**Tab "I/O":**

| Field | Giá trị |
|-------|---------|
| **Output (stdout)** | `C:\Apps\TramdocAPI\logs\service-stdout.log` |
| **Error (stderr)** | `C:\Apps\TramdocAPI\logs\service-stderr.log` |

3. Click **Install service**

4. ✅ Thông báo "Service installed successfully"

### 10.4. Khởi động Service

```powershell
# Khởi động service
Start-Service -Name "TramdocAPI"

# Đợi 10 giây
Start-Sleep -Seconds 10

# Kiểm tra status
Get-Service -Name "TramdocAPI"
```

✅ Status phải là **Running**

### 10.5. Kiểm tra API đang chạy

Mở trình duyệt trên VPS: http://localhost:8080/actuator/health

---

# 🌐 [VPS] Bước 11: Mở Firewall

> ⚡ **Thực hiện trên: VPS (trong cửa sổ Remote Desktop)**

### 11.1. Mở Port 8080 trong Windows Firewall

1. Mở **PowerShell (Admin)** trên VPS

2. Chạy lệnh:

```powershell
New-NetFirewallRule -DisplayName "Tram Doc API (8080)" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow
```

3. Kiểm tra rule đã tạo:

```powershell
Get-NetFirewallRule -DisplayName "Tram Doc API*"
```

✅ Phải thấy rule được liệt kê

### 11.2. Kiểm tra Firewall của nhà cung cấp VPS

**⚠️ Bước này tùy thuộc vào nhà cung cấp VPS của bạn:**

| Nhà cung cấp | Cách mở port |
|--------------|--------------|
| **Vultr** | Settings → Firewall → Add rule: TCP 8080 |
| **DigitalOcean** | Networking → Firewalls → Add rule |
| **Linode** | Settings → Firewall → Rules |
| **AWS** | Security Groups → Inbound rules |
| **Azure** | Network security group → Inbound |
| **VPS Việt Nam** | Tùy panel quản lý (liên hệ support) |

---

# 💻 [MÁY DEV] Bước 12: Kiểm Tra Từ Bên Ngoài

> ⚡ **Thực hiện trên: MÁY TÍNH CỦA BẠN (không phải VPS)**

### 12.1. Test API từ máy của bạn

1. **Thu nhỏ Remote Desktop** (giữ kết nối)

2. **Trên máy tính của bạn**, mở **trình duyệt**

3. Truy cập (thay `YOUR_VPS_IP` bằng IP VPS thực):
   ```
   http://YOUR_VPS_IP:8080/actuator/health
   ```
   
   Ví dụ: `http://103.123.45.67:8080/actuator/health`

4. ✅ Nếu thấy `{"status":"UP"}` → **API đã online từ internet!**

### 12.2. Mở Swagger UI

Truy cập:
```
http://YOUR_VPS_IP:8080/swagger-ui.html
```

### 12.3. Test đăng ký user

1. Trong Swagger UI, tìm **POST /api/v1/auth/register**

2. Click **Try it out**

3. Nhập body:
```json
{
  "email": "test@example.com",
  "password": "Test123456",
  "fullName": "Test User"
}
```

4. Click **Execute**

5. ✅ Response 200 hoặc 201 = Thành công!

---

# 🎉 HOÀN THÀNH DEPLOYMENT!

## 📋 Thông Tin Quan Trọng

| Thông tin | Giá trị |
|-----------|---------|
| **API URL** | `http://YOUR_VPS_IP:8080/api/v1` |
| **Swagger UI** | `http://YOUR_VPS_IP:8080/swagger-ui.html` |
| **Health Check** | `http://YOUR_VPS_IP:8080/actuator/health` |
| **Service Name** | TramdocAPI |
| **Logs** | `C:\Apps\TramdocAPI\logs\` |
| **Config** | `C:\Apps\TramdocAPI\config\application-prod.properties` |

## 🔧 Các Lệnh Quản Lý (Chạy trên VPS)

```powershell
# Xem status service
Get-Service -Name "TramdocAPI"

# Dừng service
Stop-Service -Name "TramdocAPI"

# Khởi động service
Start-Service -Name "TramdocAPI"

# Restart service
Restart-Service -Name "TramdocAPI"

# Xem log realtime
Get-Content -Path "C:\Apps\TramdocAPI\logs\tramdoc-api.log" -Wait

# Xem 50 dòng log cuối
Get-Content -Path "C:\Apps\TramdocAPI\logs\tramdoc-api.log" -Tail 50
```

---

## ❓ Xử Lý Sự Cố

### Không kết nối được VPS

| Nguyên nhân | Giải pháp |
|-------------|-----------|
| Sai IP | Kiểm tra lại IP trong email |
| Sai password | Copy/paste từ email, không gõ tay |
| VPS chưa bật | Vào panel nhà cung cấp, bật VPS |

### API không chạy được

| Lỗi | Giải pháp |
|-----|-----------|
| `Port 8080 in use` | `netstat -ano \| findstr :8080` rồi kill process |
| `Access denied MySQL` | Kiểm tra password trong config |
| `java not recognized` | Restart VPS và thử lại |

### Không truy cập được từ ngoài

| Nguyên nhân | Giải pháp |
|-------------|-----------|
| Firewall Windows | Kiểm tra rule đã tạo ở Bước 11 |
| Firewall VPS provider | Mở port trên panel nhà cung cấp |
| Service không chạy | `Get-Service -Name "TramdocAPI"` |

---

# 🌐 [BONUS] Bước 13: Sử Dụng Tên Miền Riêng

> ⚡ **Thực hiện trên: Trang quản lý domain + VPS**

### 13.1. Yêu cầu

- Bạn đã có tên miền (ví dụ: `example.com`)
- API đã chạy thành công ở Bước 12

### 13.2. Trỏ DNS về VPS

1. **Đăng nhập** vào trang quản lý domain (nơi bạn mua domain)
   - Ví dụ: Namecheap, GoDaddy, Tenten, PA Vietnam, v.v.

2. **Tìm phần quản lý DNS** (DNS Management, DNS Records, hoặc tương tự)

3. **Thêm bản ghi A record mới**:

| Type | Host/Name | Value/Points to | TTL |
|------|-----------|-----------------|-----|
| **A** | `api` | `IP_VPS_CỦA_BẠN` | 300 hoặc Auto |

**Ví dụ:**
- Domain: `tramdoc.vn`
- Host: `api`
- Value: `103.123.45.67`
- Kết quả: `api.tramdoc.vn` → `103.123.45.67`

4. **Lưu thay đổi**

5. ⏳ **Đợi 5-30 phút** để DNS cập nhật

### 13.3. Kiểm tra DNS đã hoạt động

**Trên máy DEV**, mở PowerShell:

```powershell
nslookup api.your-domain.com
```

✅ Nếu thấy IP VPS của bạn → DNS đã hoạt động!

### 13.4. Cập nhật CORS trong config

**Trên VPS**, mở file config:

```powershell
notepad C:\Apps\TramdocAPI\config\application-prod.properties
```

Sửa dòng `cors.allowed-origins`:

```properties
cors.allowed-origins=http://localhost:3000,http://api.your-domain.com,https://api.your-domain.com,https://your-domain.com
```

Lưu file và restart service:

```powershell
Restart-Service -Name "TramdocAPI"
```

### 13.5. Test với domain

Truy cập:
```
http://api.your-domain.com:8080/actuator/health
```

✅ Nếu thấy `{"status":"UP"}` → Domain đã hoạt động!

---

# 🔒 [BONUS] Bước 14: Cài HTTPS với IIS (Tùy chọn)

> ⚡ **Thực hiện trên: VPS**
>
> ⚠️ Bước này phức tạp hơn, chỉ cần làm nếu bạn muốn dùng HTTPS

### 14.1. Lợi ích của HTTPS

- 🔐 Mã hóa dữ liệu giữa client và server
- 🌐 Bắt buộc cho nhiều ứng dụng mobile và web hiện đại
- ✅ Không cần port `:8080` trong URL (dùng port 443 mặc định)

### 14.2. Cài đặt IIS

1. **Trên VPS**, mở **PowerShell (Admin)**

2. Chạy lệnh cài IIS:

```powershell
Install-WindowsFeature -Name Web-Server -IncludeManagementTools
```

3. Đợi cài đặt hoàn tất (5-10 phút)

4. Kiểm tra IIS đã cài:

```powershell
Get-Service -Name "W3SVC"
```

✅ Status phải là **Running**

### 14.3. Cài đặt URL Rewrite Module

1. Mở trình duyệt trên VPS

2. Tải **URL Rewrite**: https://www.iis.net/downloads/microsoft/url-rewrite

3. Cài đặt file `.msi` đã tải

### 14.4. Cài đặt Application Request Routing (ARR)

1. Tải **ARR 3.0**: https://www.iis.net/downloads/microsoft/application-request-routing

2. Cài đặt file `.msi` đã tải

3. Mở **IIS Manager** (Start → tìm "IIS")

4. Click vào **Server Name** → **Application Request Routing Cache**

5. Bên phải, click **Server Proxy Settings...**

6. ✅ Đánh dấu **Enable proxy** → **Apply**

### 14.5. Cấu hình Reverse Proxy

1. Trong **IIS Manager**, mở rộng **Sites** → click **Default Web Site**

2. Double-click **URL Rewrite**

3. Bên phải, click **Add Rule(s)...** → **Reverse Proxy** → OK

4. Trong hộp thoại:
   - **Inbound Rules**: `localhost:8080`
   - ✅ Enable SSL Offloading
   - Click **OK**

### 14.6. Cài SSL Certificate (Let's Encrypt miễn phí)

1. Tải **Win-ACME**: https://www.win-acme.com/

2. Giải nén vào `C:\Tools\win-acme`

3. Mở **PowerShell (Admin)**, chạy:

```powershell
cd C:\Tools\win-acme
.\wacs.exe
```

4. Làm theo hướng dẫn trên màn hình:
   - Chọn **N** (Create new certificate)
   - Chọn **1** (Default Web Site)
   - Nhập email của bạn
   - Chấp nhận điều khoản
   - Certificate sẽ được tự động cài đặt

### 14.7. Mở Port 443 trong Firewall

```powershell
New-NetFirewallRule -DisplayName "HTTPS (443)" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow
```

### 14.8. Test HTTPS

Truy cập:
```
https://api.your-domain.com/actuator/health
```

✅ Nếu thấy ổ khóa xanh và `{"status":"UP"}` → HTTPS hoạt động!

---

## 📋 Tóm Tắt URL Sau Khi Hoàn Thành

| Loại | URL |
|------|-----|
| **Không HTTPS** | `http://api.your-domain.com:8080/api/v1` |
| **Có HTTPS** | `https://api.your-domain.com/api/v1` |
| **Swagger UI** | `https://api.your-domain.com/swagger-ui.html` |

---

**Chúc bạn deploy thành công! 🚀**

*Cập nhật: 27/01/2026*
