# 🌐 Hướng Dẫn Cài Đặt Cloudflare Tunnel

> **Giải pháp cho VPS không mở được port ra internet**
>
> Cloudflare Tunnel cho phép expose API ra internet mà KHÔNG cần mở port trên firewall!

---

## 📋 Yêu Cầu

- [x] API đã chạy thành công trên localhost:8080 (Bước 9)
- [ ] Tài khoản Cloudflare (miễn phí)
- [ ] Tên miền (đã trỏ về Cloudflare)

---

## 🌐 [MÁY DEV] Bước 1: Tạo Tài Khoản Cloudflare

1. Truy cập: https://dash.cloudflare.com/sign-up

2. Đăng ký tài khoản miễn phí (dùng email thật)

3. Xác nhận email

---

## 🌐 [MÁY DEV] Bước 2: Thêm Domain Vào Cloudflare

### 2.1. Thêm site

1. Đăng nhập Cloudflare Dashboard

2. Click **Add a site**

3. Nhập tên miền của bạn (ví dụ: `tramdoc.vn`)

4. Chọn plan **Free** → Continue

### 2.2. Đổi Nameserver

1. Cloudflare sẽ hiển thị 2 nameservers, ví dụ:
   ```
   ada.ns.cloudflare.com
   bob.ns.cloudflare.com
   ```

2. Vào trang quản lý domain (nơi bạn mua domain)

3. Tìm phần **Nameservers** hoặc **DNS Servers**

4. Thay nameservers hiện tại bằng 2 nameservers của Cloudflare

5. Lưu thay đổi

6. ⏳ Đợi 5-30 phút để nameservers cập nhật

7. Quay lại Cloudflare Dashboard → Click **Check nameservers**

---

## 🌐 [VPS] Bước 3: Cài Đặt Cloudflared

### 3.1. Tải Cloudflared

Trên VPS, mở **PowerShell** và chạy:

```powershell
# Tạo thư mục
New-Item -ItemType Directory -Force -Path "C:\Tools\cloudflared"

# Tải cloudflared
Invoke-WebRequest -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -OutFile "C:\Tools\cloudflared\cloudflared.exe"

# Kiểm tra
& "C:\Tools\cloudflared\cloudflared.exe" --version
```

✅ Nếu thấy version → Cài đặt thành công!

### 3.2. Đăng nhập Cloudflare

```powershell
& "C:\Tools\cloudflared\cloudflared.exe" tunnel login
```

- Một link sẽ hiển thị trong terminal
- **Copy link** và mở trong trình duyệt trên VPS
- Chọn domain bạn muốn sử dụng
- Click **Authorize**
- Quay lại terminal → sẽ hiển thị "You have successfully logged in"

---

## 🌐 [VPS] Bước 4: Tạo Tunnel

### 4.1. Tạo tunnel mới

```powershell
& "C:\Tools\cloudflared\cloudflared.exe" tunnel create tramdoc-api
```

Lưu lại **Tunnel ID** được hiển thị (ví dụ: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`)

### 4.2. Tạo file cấu hình

```powershell
# Tạo thư mục config
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.cloudflared"

# Tạo file config
notepad "$env:USERPROFILE\.cloudflared\config.yml"
```

Paste nội dung sau vào Notepad (thay TUNNEL_ID và DOMAIN):

```yaml
tunnel: TUNNEL_ID_CUA_BAN
credentials-file: C:\Users\Administrator\.cloudflared\TUNNEL_ID_CUA_BAN.json

ingress:
  - hostname: api.your-domain.com
    service: http://localhost:8080
  - service: http_status:404
```

**Ví dụ:**
```yaml
tunnel: a1b2c3d4-e5f6-7890-abcd-ef1234567890
credentials-file: C:\Users\Administrator\.cloudflared\a1b2c3d4-e5f6-7890-abcd-ef1234567890.json

ingress:
  - hostname: api.tramdoc.vn
    service: http://localhost:8080
  - service: http_status:404
```

Lưu file (Ctrl+S) và đóng Notepad.

### 4.3. Tạo DNS record

```powershell
& "C:\Tools\cloudflared\cloudflared.exe" tunnel route dns tramdoc-api api.your-domain.com
```

Thay `api.your-domain.com` bằng subdomain thực của bạn.

---

## 🌐 [VPS] Bước 5: Chạy Tunnel

### 5.1. Test tunnel

```powershell
& "C:\Tools\cloudflared\cloudflared.exe" tunnel run tramdoc-api
```

Giữ nguyên terminal, mở trình duyệt và truy cập:
```
https://api.your-domain.com/actuator/health
```

✅ Nếu thấy `{"status":"UP"}` → **TUNNEL HOẠT ĐỘNG!**

Nhấn **Ctrl+C** để dừng test.

### 5.2. Cài đặt Tunnel như Windows Service

```powershell
& "C:\Tools\cloudflared\cloudflared.exe" service install
```

Tunnel sẽ tự động chạy khi Windows khởi động!

### 5.3. Khởi động service

```powershell
Start-Service -Name "Cloudflared"
Get-Service -Name "Cloudflared"
```

---

## 🎉 Hoàn Thành!

### URL API của bạn:

| Loại | URL |
|------|-----|
| **API Base** | `https://api.your-domain.com/api/v1` |
| **Swagger UI** | `https://api.your-domain.com/swagger-ui.html` |
| **Health Check** | `https://api.your-domain.com/actuator/health` |

### Lợi ích:

- ✅ **HTTPS miễn phí** (Cloudflare tự động cấp SSL)
- ✅ **Không cần mở port** trên VPS
- ✅ **Bảo vệ DDoS** từ Cloudflare
- ✅ **Tự động chạy** khi VPS khởi động

---

## 🔧 Quản Lý Tunnel

```powershell
# Xem status
Get-Service -Name "Cloudflared"

# Restart tunnel
Restart-Service -Name "Cloudflared"

# Xem logs
Get-Content -Path "C:\Windows\System32\config\systemprofile\.cloudflared\cloudflared.log" -Tail 50

# Liệt kê tunnels
& "C:\Tools\cloudflared\cloudflared.exe" tunnel list
```

---

## ❓ Xử Lý Sự Cố

### Tunnel không chạy

1. Kiểm tra file config đúng cú pháp YAML
2. Kiểm tra Tunnel ID đúng
3. Kiểm tra API đang chạy trên localhost:8080

### DNS không phân giải

- Đợi 5-10 phút để DNS cập nhật
- Kiểm tra đã chạy lệnh `tunnel route dns`

### 502 Bad Gateway

- API không chạy trên localhost:8080
- Kiểm tra: `Invoke-RestMethod -Uri "http://localhost:8080/actuator/health"`

---

## 📝 Cập Nhật CORS

Sau khi có domain, cập nhật file config API:

```powershell
notepad C:\Apps\TramdocAPI\config\application-prod.properties
```

Sửa dòng:
```properties
cors.allowed-origins=http://localhost:3000,https://api.your-domain.com,https://your-domain.com
```

Restart API:
```powershell
Restart-Service -Name "TramdocAPI"
```

---

*Cập nhật: 27/01/2026*
