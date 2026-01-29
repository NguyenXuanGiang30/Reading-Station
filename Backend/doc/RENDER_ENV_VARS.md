# 🔧 Render.com Environment Variables

## 📋 Danh Sách Environment Variables Cần Thiết

Copy các biến sau vào Render Web Service → Environment:

---

### 🗄️ Database Configuration

```bash
DATABASE_URL=jdbc:postgresql://dpg-xxx-xxx.singapore-postgres.render.com:5432/tram_doc_db
DATABASE_USERNAME=tram_doc_user
DATABASE_PASSWORD=<password từ Render PostgreSQL>
```

**⚠️ Lưu ý:**
- Thêm `jdbc:` vào đầu URL
- Lấy password từ tab **"Info"** của PostgreSQL service

---

### ⚙️ Application Configuration

```bash
SPRING_PROFILE=postgres
DDL_AUTO=update
FLYWAY_ENABLED=false
```

---

### 🔐 Security

```bash
JWT_SECRET=<tạo secret key dài ít nhất 256 bits>
```

**Tạo JWT Secret:**
```powershell
# PowerShell
-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 64 | ForEach-Object {[char]$_})
```

Hoặc dùng: https://www.random.org/strings/

---

### 🌐 CORS

```bash
CORS_ORIGINS=*
```

Hoặc chỉ định domain cụ thể:
```bash
CORS_ORIGINS=https://your-frontend.com,https://www.your-frontend.com
```

---

### 📊 Logging (Optional)

```bash
LOG_LEVEL=INFO
LOG_LEVEL_APP=INFO
SHOW_SQL=false
```

---

## 🚀 Quick Setup Script

Sau khi có Database URL từ Render, chạy:

```powershell
.\parse-render-db-url.ps1
```

Script sẽ tự động parse và tạo các environment variables.

---

## ✅ Checklist

- [ ] `DATABASE_URL` (với `jdbc:` prefix)
- [ ] `DATABASE_USERNAME`
- [ ] `DATABASE_PASSWORD`
- [ ] `SPRING_PROFILE=postgres`
- [ ] `DDL_AUTO=update`
- [ ] `FLYWAY_ENABLED=false`
- [ ] `JWT_SECRET` (secret key mạnh)
- [ ] `CORS_ORIGINS`

---

**Sau khi set xong, click "Save Changes" và Render sẽ tự động redeploy!**
