package com.tramdoc.service;

import com.tramdoc.dto.request.LoginRequest;
import com.tramdoc.dto.request.RegisterRequest;
import com.tramdoc.dto.response.AuthResponse;
import com.tramdoc.dto.response.UserResponse;
import com.tramdoc.entity.User;
import com.tramdoc.exception.BadRequestException;
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
                request.getPassword()
            )
        );
        
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
        String email = tokenProvider.getEmailFromToken(refreshToken);
        
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
