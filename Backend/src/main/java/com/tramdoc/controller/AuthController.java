package com.tramdoc.controller;

import com.tramdoc.dto.request.FacebookLoginRequest;
import com.tramdoc.dto.request.GoogleLoginRequest;
import com.tramdoc.dto.request.LoginRequest;
import com.tramdoc.dto.request.RefreshTokenRequest;
import com.tramdoc.dto.request.RegisterRequest;
import com.tramdoc.dto.response.AuthResponse;
import com.tramdoc.service.AuthService;
import com.tramdoc.service.OAuth2Service;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Authentication", description = "APIs for user authentication")
public class AuthController {

    @Autowired
    private AuthService authService;

    @Autowired
    private OAuth2Service oauth2Service;

    @PostMapping("/register")
    @Operation(summary = "Register new user", description = "Register a new user with email and password")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        AuthResponse response = authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/login")
    @Operation(summary = "Login", description = "Login with email and password")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/google")
    @Operation(summary = "Login with Google", description = "Authenticate using Google OAuth2 access token")
    public ResponseEntity<AuthResponse> loginWithGoogle(@Valid @RequestBody GoogleLoginRequest request) {
        AuthResponse response = oauth2Service.loginWithGoogle(request.getAccessToken());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/facebook")
    @Operation(summary = "Login with Facebook", description = "Authenticate using Facebook OAuth2 access token")
    public ResponseEntity<AuthResponse> loginWithFacebook(@Valid @RequestBody FacebookLoginRequest request) {
        AuthResponse response = oauth2Service.loginWithFacebook(request.getAccessToken());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/refresh")
    @Operation(summary = "Refresh token", description = "Refresh JWT access token using refresh token")
    public ResponseEntity<AuthResponse> refreshToken(@Valid @RequestBody RefreshTokenRequest request) {
        AuthResponse response = authService.refreshToken(request.getRefreshToken());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/logout")
    @Operation(summary = "Logout", description = "Logout user (client should remove token)")
    public ResponseEntity<Void> logout() {
        // JWT is stateless, client should remove token
        return ResponseEntity.ok().build();
    }
}
