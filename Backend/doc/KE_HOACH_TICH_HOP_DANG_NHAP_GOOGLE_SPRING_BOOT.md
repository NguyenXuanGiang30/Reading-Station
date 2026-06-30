# Kế hoạch tích hợp/chuẩn hóa đăng nhập Google cho Backend (Spring Boot)

**Dự án:** Reading Station - Backend  
**Đường dẫn:** `D:\Reading_Station\Backend`  
**Ngày cập nhật:** 2026-03-14

---

## 1) Mục tiêu tài liệu

Tổng hợp nhanh các nguồn tham khảo + dự án mẫu Spring Boot dùng đăng nhập Google, sau đó chuyển thành **checklist việc cần làm** cho backend hiện tại.

---

## 2) Nguồn tham khảo đã tìm

## Tài liệu chính thức
1. Spring Security OAuth2 Login
   - https://docs.spring.io/spring-security/reference/servlet/oauth2/login/index.html
   - Điểm chính: hỗ trợ sẵn “Login with Google”, dùng OAuth2/OpenID Connect.

2. Spring Security - Core Configuration OAuth2 Login
   - https://docs.spring.io/spring-security/reference/servlet/oauth2/login/core.html
   - Điểm chính: cấu hình `spring.security.oauth2.client.registration.google.*`, redirect mặc định `{baseUrl}/login/oauth2/code/{registrationId}`.

3. Spring Guide: Spring Boot and OAuth2
   - https://spring.io/guides/tutorials/spring-boot-oauth2/
   - Điểm chính: lộ trình mẫu từ basic login đến multi-provider.

4. Google OpenID Connect
   - https://developers.google.com/identity/openid-connect/openid-connect
   - Điểm chính: cần tạo OAuth client trong Google Cloud, cấu hình consent screen, redirect URI, xác thực token đúng chuẩn OIDC.

## Dự án mẫu mã nguồn
1. Spring official tutorial repo
   - https://github.com/spring-guides/tut-spring-boot-oauth2

2. Spring Security sample oauth2 login
   - https://github.com/spring-projects/spring-security-samples/tree/main/servlet/spring-boot/java/oauth2/login

3. Callicoder social login demo
   - https://github.com/callicoder/spring-boot-react-oauth2-social-login-demo
   - Có flow callback OAuth2 + JWT cho frontend SPA.

---

## 3) Hiện trạng backend Reading Station (đã rà nhanh)

### Đã có sẵn
- `spring-boot-starter-security`
- JWT auth (`JwtAuthenticationFilter`, `JwtTokenProvider`)
- Endpoint OAuth custom:
  - `POST /api/v1/auth/google`
  - `POST /api/v1/auth/facebook`
- `OAuth2Service` gọi `https://www.googleapis.com/oauth2/v3/userinfo` bằng access token từ client.
- Entity có `AuthProvider`, `providerId` để link account.

### Chưa thấy (hoặc chưa dùng)
- Chưa dùng cơ chế `oauth2Login()` chuẩn của Spring Security (redirect/login page callback server-side).
- Chưa có dependency `spring-boot-starter-oauth2-client` trong `pom.xml`.
- Chưa cấu hình `spring.security.oauth2.client.registration.google.*` trong `application*.properties`.

---

## 4) Khuyến nghị hướng triển khai

Có 2 hướng, tùy nhu cầu frontend/mobile:

## Hướng A (giữ kiến trúc hiện tại - mobile friendly, nhanh)
Frontend lấy `access_token` từ Google SDK -> gửi backend `/api/v1/auth/google` -> backend xác thực user + cấp JWT nội bộ.

**Ưu điểm:** ít đổi code hiện có, phù hợp app mobile/web tách rời.  
**Nhược điểm:** cần làm chặt khâu verify token/claims để an toàn.

## Hướng B (chuẩn Spring OAuth2 Login - web server flow)
Backend điều khiển redirect OAuth2 toàn bộ qua `oauth2Login()`.

**Ưu điểm:** theo chuẩn Spring Security, ít tự viết flow.  
**Nhược điểm:** đổi kiến trúc auth hiện tại, cần xử lý callback + frontend integration kỹ hơn.

> Với Reading Station hiện tại (đang có JWT + endpoint `/auth/google`), nên ưu tiên **Hướng A nâng cấp bảo mật**, rồi mới cân nhắc Hướng B nếu cần web-login full redirect.

---

## 5) Checklist việc cần làm (đề xuất theo mức ưu tiên)

## P0 - Bắt buộc (an toàn + ổn định)
1. **Tách Google OAuth config ra biến môi trường**
   - `GOOGLE_CLIENT_ID`
   - `GOOGLE_ISSUER` (accounts.google.com)
   - Không hardcode secret/key trong repo.

2. **Xác thực token chặt hơn ở backend**
   - Không chỉ gọi `userinfo`; cần verify thêm claim quan trọng:
     - `iss` hợp lệ
     - `aud` khớp `GOOGLE_CLIENT_ID`
     - `exp` chưa hết hạn
     - `email_verified = true`
   - Nếu dùng ID token từ frontend thì verify chữ ký JWT theo Google JWK/OIDC discovery.

3. **Chuẩn hóa xử lý lỗi OAuth**
   - Phân biệt lỗi: token hết hạn / token sai / không có email / user bị khóa.
   - Trả mã lỗi thống nhất cho frontend (`401`, `400`, message code).

4. **Cập nhật Security/CORS cho Google login flow**
   - Whitelist origin môi trường dev/prod rõ ràng.
   - Test CORS với frontend thật.

5. **Bổ sung test cho `/api/v1/auth/google`**
   - Unit test service logic.
   - Integration test endpoint thành công/thất bại.

## P1 - Nên làm sớm (vận hành tốt)
6. **Thêm audit log cho social login**
   - Log event: login success/fail, provider, userId/email (ẩn bớt thông tin nhạy cảm).

7. **Ràng buộc account linking an toàn**
   - Nếu email đã tồn tại tài khoản LOCAL, yêu cầu bước xác minh trước khi tự động link (tránh takeover).

8. **Cập nhật tài liệu API + Swagger**
   - Ví dụ payload `GoogleLoginRequest`.
   - Các mã lỗi trả về.

9. **Bảo vệ rate limit cho endpoint social login**
   - Giảm brute-force/token abuse.

## P2 - Mở rộng
10. **Đổi sang flow OIDC đầy đủ (nếu cần web redirect chuẩn)**
    - Thêm `spring-boot-starter-oauth2-client`.
    - Cấu hình `spring.security.oauth2.client.registration.google`.
    - Tùy biến success handler để phát JWT nội bộ.

11. **Thống nhất chiến lược đa provider (Google/Facebook/Apple)**
    - Interface provider verifier chung.
    - Mapping claim chuẩn hóa.

---

## 6) Thay đổi kỹ thuật cụ thể gợi ý

## 6.1 pom.xml
- Nếu đi Hướng B hoặc muốn dùng class hỗ trợ OAuth client:
```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-oauth2-client</artifactId>
</dependency>
```

## 6.2 application.properties
- Bổ sung biến môi trường an toàn:
```properties
oauth2.google.client-id=${GOOGLE_CLIENT_ID:}
oauth2.google.issuer=https://accounts.google.com
```

(Nếu dùng Hướng B thì thêm `spring.security.oauth2.client.registration.google.*`)

## 6.3 OAuth2Service
- Tách method verify token claims.
- Chuẩn hóa exception type (`InvalidTokenException`, `AccountLinkingException`...).
- Bổ sung kiểm tra `email_verified`.

## 6.4 SecurityConfig
- Giữ `/api/v1/auth/google` ở permitAll (đã có), nhưng thêm rate limit/filter nếu cần.

---

## 7) Kịch bản kiểm thử cần có

1. Token Google hợp lệ -> trả JWT nội bộ + user info.
2. Token hết hạn -> 401.
3. Token sai audience -> 401.
4. Email chưa verify -> 400/401 theo policy.
5. User local trùng email -> xử lý account linking đúng luật.
6. CORS đúng cho frontend domain production.

---

## 8) Đầu ra mong đợi sau khi hoàn thành

- Đăng nhập Google hoạt động ổn định trên dev + production.
- Flow social login được bảo vệ đúng chuẩn cơ bản OIDC.
- Có test và tài liệu rõ để team frontend tích hợp nhanh.

---

## 9) Kế hoạch triển khai ngắn (ước lượng)

- **Ngày 1:** cấu hình env + verify claims + refactor lỗi
- **Ngày 2:** test integration + cập nhật swagger/docs
- **Ngày 3:** hardening (rate-limit, account linking policy) + deploy staging

---

## 10) Ghi chú cho đội frontend

- Nếu dùng Google Identity Services, frontend nên gửi **ID token** (khuyến nghị) hoặc access token theo thiết kế thống nhất.
- Cần chốt contract payload cho `POST /api/v1/auth/google` để tránh mismatch.
- Token nội bộ của hệ thống vẫn là JWT backend cấp ra, frontend không dùng trực tiếp token Google cho API nội bộ.
