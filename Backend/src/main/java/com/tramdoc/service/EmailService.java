package com.tramdoc.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    @Autowired
    private JavaMailSender mailSender;

    @Value("${spring.mail.username:noreply@tramdoc.com}")
    private String fromEmail;

    @Value("${app.name:Trạm Đọc}")
    private String appName;

    public void sendOtpEmail(String toEmail, String otp, String userName) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromEmail);
        message.setTo(toEmail);
        message.setSubject(appName + " - Mã xác thực đặt lại mật khẩu");
        message.setText(buildOtpEmailContent(otp, userName));

        mailSender.send(message);
    }

    private String buildOtpEmailContent(String otp, String userName) {
        return String.format("""
                Xin chào %s,

                Bạn đã yêu cầu đặt lại mật khẩu cho tài khoản %s.

                Mã xác thực (OTP) của bạn là:

                    🔐  %s

                Mã này sẽ hết hạn sau 10 phút.

                Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.

                Trân trọng,
                Đội ngũ %s
                """,
                userName != null ? userName : "bạn",
                appName,
                otp,
                appName);
    }

    public void sendWelcomeEmail(String toEmail, String userName) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromEmail);
        message.setTo(toEmail);
        message.setSubject("Chào mừng bạn đến với " + appName + "!");
        message.setText(String.format("""
                Xin chào %s,

                Chúc mừng bạn đã đăng ký thành công tài khoản %s!

                Bắt đầu hành trình đọc sách của bạn ngay hôm nay.

                Trân trọng,
                Đội ngũ %s
                """,
                userName,
                appName,
                appName));

        mailSender.send(message);
    }
}
