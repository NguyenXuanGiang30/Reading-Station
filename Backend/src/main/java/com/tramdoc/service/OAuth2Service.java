package com.tramdoc.service;

import com.tramdoc.dto.response.AuthResponse;
import com.tramdoc.dto.response.UserResponse;
import com.tramdoc.entity.AuthProvider;
import com.tramdoc.entity.User;
import com.tramdoc.exception.BadRequestException;
import com.tramdoc.repository.UserRepository;
import com.tramdoc.security.JwtTokenProvider;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.util.Map;
import java.util.Optional;

/**
 * Service for handling OAuth2 authentication with Google and Facebook.
 */
@Service
@Slf4j
public class OAuth2Service {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtTokenProvider tokenProvider;

    private final WebClient webClient;

    @Value("${oauth2.google.userinfo-url:https://www.googleapis.com/oauth2/v3/userinfo}")
    private String googleUserInfoUrl;

    @Value("${oauth2.facebook.userinfo-url:https://graph.facebook.com/me}")
    private String facebookUserInfoUrl;

    public OAuth2Service() {
        this.webClient = WebClient.builder().build();
    }

    /**
     * Authenticate user with Google access token.
     */
    @Transactional
    @SuppressWarnings("unchecked")
    public AuthResponse loginWithGoogle(String accessToken) {
        try {
            // Verify token with Google and get user info
            Map<String, Object> userInfo = webClient.get()
                    .uri(googleUserInfoUrl)
                    .header("Authorization", "Bearer " + accessToken)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();

            if (userInfo == null || !userInfo.containsKey("email")) {
                throw new BadRequestException("Không thể xác thực với Google");
            }

            String email = (String) userInfo.get("email");
            String name = (String) userInfo.get("name");
            String picture = (String) userInfo.get("picture");
            String googleId = (String) userInfo.get("sub");

            log.info("Google login for email: {}", email);

            User user = findOrCreateUser(email, name, picture, googleId, AuthProvider.GOOGLE);
            return generateAuthResponse(user);

        } catch (WebClientResponseException e) {
            log.error("Google OAuth error: {}", e.getMessage());
            throw new BadRequestException("Token Google không hợp lệ hoặc đã hết hạn");
        }
    }

    /**
     * Authenticate user with Facebook access token.
     */
    @Transactional
    @SuppressWarnings("unchecked")
    public AuthResponse loginWithFacebook(String accessToken) {
        try {
            // Verify token with Facebook and get user info
            Map<String, Object> userInfo = webClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .scheme("https")
                            .host("graph.facebook.com")
                            .path("/me")
                            .queryParam("fields", "id,name,email,picture.type(large)")
                            .queryParam("access_token", accessToken)
                            .build())
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();

            if (userInfo == null) {
                throw new BadRequestException("Không thể xác thực với Facebook");
            }

            String email = (String) userInfo.get("email");
            String name = (String) userInfo.get("name");
            String facebookId = (String) userInfo.get("id");

            // Extract picture URL from nested structure
            String picture = null;
            if (userInfo.containsKey("picture")) {
                Map<String, Object> pictureData = (Map<String, Object>) userInfo.get("picture");
                if (pictureData != null && pictureData.containsKey("data")) {
                    Map<String, Object> data = (Map<String, Object>) pictureData.get("data");
                    picture = (String) data.get("url");
                }
            }

            // Facebook may not return email if user denied permission
            if (email == null) {
                throw new BadRequestException("Không thể lấy email từ Facebook. Vui lòng cấp quyền truy cập email.");
            }

            log.info("Facebook login for email: {}", email);

            User user = findOrCreateUser(email, name, picture, facebookId, AuthProvider.FACEBOOK);
            return generateAuthResponse(user);

        } catch (WebClientResponseException e) {
            log.error("Facebook OAuth error: {}", e.getMessage());
            throw new BadRequestException("Token Facebook không hợp lệ hoặc đã hết hạn");
        }
    }

    /**
     * Find existing user or create new one for OAuth login.
     * If user exists with same email (registered via email/password), link the
     * account.
     */
    private User findOrCreateUser(String email, String name, String avatarUrl,
            String providerId, AuthProvider provider) {
        // First, try to find by provider ID
        Optional<User> existingByProvider = userRepository
                .findByAuthProviderAndProviderId(provider, providerId);

        if (existingByProvider.isPresent()) {
            User user = existingByProvider.get();
            // Update avatar if changed
            if (avatarUrl != null && !avatarUrl.equals(user.getAvatarUrl())) {
                user.setAvatarUrl(avatarUrl);
                user = userRepository.save(user);
            }
            return user;
        }

        // Try to find by email (for account linking)
        Optional<User> existingByEmail = userRepository.findByEmail(email);

        if (existingByEmail.isPresent()) {
            User user = existingByEmail.get();
            // Link the OAuth provider to existing account
            // Only update if not already linked to another provider
            if (user.getAuthProvider() == AuthProvider.LOCAL ||
                    user.getAuthProvider() == provider) {
                user.setAuthProvider(provider);
                user.setProviderId(providerId);
                if (user.getAvatarUrl() == null && avatarUrl != null) {
                    user.setAvatarUrl(avatarUrl);
                }
                user = userRepository.save(user);
                log.info("Linked {} account to existing user: {}", provider, email);
            }
            return user;
        }

        // Create new user
        User newUser = User.builder()
                .email(email)
                .fullName(name != null ? name : email.split("@")[0])
                .avatarUrl(avatarUrl)
                .authProvider(provider)
                .providerId(providerId)
                .password(null) // OAuth users don't have password
                .isActive(true)
                .build();

        newUser = userRepository.save(newUser);
        log.info("Created new user via {}: {}", provider, email);

        return newUser;
    }

    /**
     * Generate JWT tokens and auth response for user.
     */
    private AuthResponse generateAuthResponse(User user) {
        String token = tokenProvider.generateToken(user.getId(), user.getEmail());
        String refreshToken = tokenProvider.generateRefreshToken(user.getId(), user.getEmail());

        return AuthResponse.builder()
                .token(token)
                .refreshToken(refreshToken)
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
