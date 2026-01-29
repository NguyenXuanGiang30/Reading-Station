package com.tramdoc.service;

import com.tramdoc.dto.request.UpdateProfileRequest;
import com.tramdoc.dto.response.UserResponse;
import com.tramdoc.entity.User;
import com.tramdoc.exception.ResourceNotFoundException;
import com.tramdoc.repository.UserRepository;
import com.tramdoc.security.UserPrincipal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {
    
    @Autowired
    private UserRepository userRepository;
    
    public UserResponse getCurrentUser() {
        UserPrincipal userPrincipal = (UserPrincipal) SecurityContextHolder.getContext()
            .getAuthentication().getPrincipal();
        
        User user = userRepository.findById(userPrincipal.getId())
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        
        return mapToUserResponse(user);
    }
    
    public UserResponse getUserById(Long id) {
        User user = userRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + id));
        
        return mapToUserResponse(user);
    }
    
    @Transactional
    public UserResponse updateProfile(UpdateProfileRequest request) {
        UserPrincipal userPrincipal = (UserPrincipal) SecurityContextHolder.getContext()
            .getAuthentication().getPrincipal();
        
        User user = userRepository.findById(userPrincipal.getId())
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        
        if (request.getFullName() != null) {
            user.setFullName(request.getFullName());
        }
        if (request.getBio() != null) {
            user.setBio(request.getBio());
        }
        if (request.getAvatarUrl() != null) {
            user.setAvatarUrl(request.getAvatarUrl());
        }
        
        user = userRepository.save(user);
        return mapToUserResponse(user);
    }
    
    public UserResponse mapToUserResponse(User user) {
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
