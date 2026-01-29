package com.tramdoc.service;

import com.tramdoc.dto.request.ChangePasswordRequest;
import com.tramdoc.dto.request.ForgotPasswordRequest;
import com.tramdoc.dto.request.LoginRequest;
import com.tramdoc.dto.request.RegisterRequest;
import com.tramdoc.dto.request.ResetPasswordRequest;
import com.tramdoc.dto.request.VerifyOtpRequest;
import com.tramdoc.dto.response.AuthResponse;
import com.tramdoc.dto.response.UserResponse;
import com.tramdoc.entity.PasswordResetOtp;
import com.tramdoc.entity.User;
import com.tramdoc.exception.BadRequestException;
import com.tramdoc.repository.PasswordResetOtpRepository;
import com.tramdoc.repository.UserRepository;
import com.tramdoc.security.JwtTokenProvider;
import com.tramdoc.security.UserPrincipal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;

@Service
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtTokenProvider tokenProvider;

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private PasswordResetOtpRepository otpRepository;

    @Autowired
    private EmailService emailService;

    private static final SecureRandom secureRandom = new SecureRandom();

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new BadRequestException("Email đã được sử dụng");
        }

        User user = User.builder()
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .fullName(request.getFullName())
                .isActive(true)
                .build();

        user = userRepository.save(user);

        String token = tokenProvider.generateToken(user.getId(), user.getEmail());
        String refreshToken = tokenProvider.generateRefreshToken(user.getId(), user.getEmail());

        return AuthResponse.builder()
                .token(token)
                .refreshToken(refreshToken)
                .user(mapToUserResponse(user))
                .build();
    }

    public AuthResponse login(LoginRequest request) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getEmail(),
                        request.getPassword()));

        SecurityContextHolder.getContext().setAuthentication(authentication);

        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        User user = userRepository.findById(userPrincipal.getId())
                .orElseThrow(() -> new BadRequestException("User not found"));

        String token = tokenProvider.generateToken(user.getId(), user.getEmail());
        String refreshToken = tokenProvider.generateRefreshToken(user.getId(), user.getEmail());

        return AuthResponse.builder()
                .token(token)
                .refreshToken(refreshToken)
                .user(mapToUserResponse(user))
                .build();
    }

    public AuthResponse refreshToken(String refreshToken) {
        if (!tokenProvider.validateToken(refreshToken)) {
            throw new BadRequestException("Refresh token không hợp lệ");
        }

        Long userId = tokenProvider.getUserIdFromToken(refreshToken);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BadRequestException("User not found"));

        String newToken = tokenProvider.generateToken(user.getId(), user.getEmail());
        String newRefreshToken = tokenProvider.generateRefreshToken(user.getId(), user.getEmail());

        return AuthResponse.builder()
                .token(newToken)
                .refreshToken(newRefreshToken)
                .user(mapToUserResponse(user))
                .build();
    }

    @Transactional
    public void changePassword(ChangePasswordRequest request) {
        UserPrincipal userPrincipal = (UserPrincipal) SecurityContextHolder.getContext()
                .getAuthentication().getPrincipal();

        User user = userRepository.findById(userPrincipal.getId())
                .orElseThrow(() -> new BadRequestException("User not found"));

        if (user.getPassword() == null) {
            throw new BadRequestException("Tài khoản đăng nhập bằng mạng xã hội không thể đổi mật khẩu");
        }

        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
            throw new BadRequestException("Mật khẩu hiện tại không đúng");
        }

        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new BadRequestException("Mật khẩu mới không khớp");
        }

        if (passwordEncoder.matches(request.getNewPassword(), user.getPassword())) {
            throw new BadRequestException("Mật khẩu mới phải khác mật khẩu hiện tại");
        }

        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
    }

    // ========== Forgot Password with OTP ==========

    @Transactional
    public void forgotPassword(ForgotPasswordRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElse(null);

        // Always return success to prevent email enumeration attacks
        if (user == null) {
            return;
        }

        // Check if user has a password (not OAuth user)
        if (user.getPassword() == null) {
            throw new BadRequestException(
                    "Tài khoản đăng nhập bằng mạng xã hội. Vui lòng đăng nhập bằng Google/Facebook.");
        }

        // Invalidate all previous OTPs
        otpRepository.markAllAsUsedByUserId(user.getId());

        // Generate 6-digit OTP
        String otp = generateOtp();

        // Save OTP with 10 minute expiry
        PasswordResetOtp resetOtp = PasswordResetOtp.builder()
                .user(user)
                .otp(otp)
                .expiresAt(LocalDateTime.now().plusMinutes(10))
                .used(false)
                .build();

        otpRepository.save(resetOtp);

        // Send email
        try {
            emailService.sendOtpEmail(user.getEmail(), otp, user.getFullName());
        } catch (Exception e) {
            throw new BadRequestException("Không thể gửi email. Vui lòng thử lại sau.");
        }
    }

    public boolean verifyOtp(VerifyOtpRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BadRequestException("Email không tồn tại"));

        PasswordResetOtp otp = otpRepository
                .findByUserIdAndOtpAndUsedFalse(user.getId(), request.getOtp())
                .orElseThrow(() -> new BadRequestException("Mã OTP không đúng"));

        if (!otp.isValid()) {
            throw new BadRequestException("Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.");
        }

        return true;
    }

    @Transactional
    public void resetPassword(ResetPasswordRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BadRequestException("Email không tồn tại"));

        PasswordResetOtp otp = otpRepository
                .findByUserIdAndOtpAndUsedFalse(user.getId(), request.getOtp())
                .orElseThrow(() -> new BadRequestException("Mã OTP không đúng"));

        if (!otp.isValid()) {
            throw new BadRequestException("Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.");
        }

        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new BadRequestException("Mật khẩu mới không khớp");
        }

        // Update password
        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        // Mark OTP as used
        otp.setUsed(true);
        otpRepository.save(otp);

        // Invalidate all other OTPs for this user
        otpRepository.markAllAsUsedByUserId(user.getId());
    }

    private String generateOtp() {
        int otp = 100000 + secureRandom.nextInt(900000); // 6-digit number
        return String.valueOf(otp);
    }

    private UserResponse mapToUserResponse(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .avatarUrl(user.getAvatarUrl())
                .bio(user.getBio())
                .createdAt(user.getCreatedAt())
                .build();
    }
}
