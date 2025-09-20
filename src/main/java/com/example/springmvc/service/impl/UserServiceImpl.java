package com.example.springmvc.service.impl;

import com.example.springmvc.common.exception.ResourceExistsException;
import com.example.springmvc.common.exception.ResourceNotFoundException;
import com.example.springmvc.common.utils.BeanUtil;
import com.example.springmvc.common.utils.PasswordUtil;
import com.example.springmvc.dto.UserCreateRequest;
import com.example.springmvc.dto.UserResponse;
import com.example.springmvc.dto.UserUpdateRequest;
import com.example.springmvc.entity.User;
import com.example.springmvc.repository.UserRepository;
import com.example.springmvc.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 用户业务逻辑层实现类
 * 
 * 实现用户相关的业务操作
 * 提供事务支持和业务逻辑处理
 * 
 * @author example
 * @version 1.0.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;

    @Override
    @Transactional
    public UserResponse createUser(UserCreateRequest request) {
        log.info("创建用户: {}", request.getUsername());
        
        // 检查用户名是否已存在
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new ResourceExistsException("用户", "用户名", request.getUsername());
        }
        
        // 检查邮箱是否已存在
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new ResourceExistsException("用户", "邮箱", request.getEmail());
        }
        
        // 创建用户实体
        User user = new User();
        BeanUtils.copyProperties(request, user);
        
        // 加密密码
        user.setPassword(PasswordUtil.encryptPassword(request.getPassword()));
        
        // 保存用户
        User savedUser = userRepository.save(user);
        
        log.info("用户创建成功: {}", savedUser.getId());
        return convertToResponse(savedUser);
    }

    @Override
    public UserResponse getUserById(Long id) {
        log.debug("根据ID获取用户: {}", id);
        
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("用户", "ID", id));
        
        return convertToResponse(user);
    }

    @Override
    public UserResponse getUserByUsername(String username) {
        log.debug("根据用户名获取用户: {}", username);
        
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("用户", "用户名", username));
        
        return convertToResponse(user);
    }

    @Override
    @Transactional
    public UserResponse updateUser(Long id, UserUpdateRequest request) {
        log.info("更新用户: {}", id);
        
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("用户", "ID", id));
        
        // 如果更新邮箱，检查邮箱是否已被其他用户使用
        if (request.getEmail() != null && !request.getEmail().equals(user.getEmail())) {
            if (userRepository.existsByEmail(request.getEmail())) {
                throw new ResourceExistsException("用户", "邮箱", request.getEmail());
            }
        }
        
        // 更新用户信息（忽略null值）
        BeanUtil.copyPropertiesIgnoreNull(request, user);
        
        User updatedUser = userRepository.save(user);
        
        log.info("用户更新成功: {}", updatedUser.getId());
        return convertToResponse(updatedUser);
    }

    @Override
    @Transactional
    public void deleteUser(Long id) {
        log.info("删除用户: {}", id);
        
        if (!userRepository.existsById(id)) {
            throw new ResourceNotFoundException("用户", "ID", id);
        }
        
        userRepository.deleteById(id);
        log.info("用户删除成功: {}", id);
    }

    @Override
    public List<UserResponse> getAllUsers() {
        log.debug("获取所有用户列表");
        
        List<User> users = userRepository.findAll();
        return users.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    @Override
    public Page<UserResponse> getUsers(Pageable pageable) {
        log.debug("分页获取用户列表: page={}, size={}", pageable.getPageNumber(), pageable.getPageSize());
        
        Page<User> userPage = userRepository.findAll(pageable);
        return userPage.map(this::convertToResponse);
    }

    @Override
    public Page<UserResponse> getUsersByStatus(Integer status, Pageable pageable) {
        log.debug("根据状态分页获取用户列表: status={}, page={}, size={}", 
                status, pageable.getPageNumber(), pageable.getPageSize());
        
        Page<User> userPage = userRepository.findByStatus(status, pageable);
        return userPage.map(this::convertToResponse);
    }

    @Override
    public Page<UserResponse> searchUsers(String keyword, Pageable pageable) {
        log.debug("搜索用户: keyword={}, page={}, size={}", 
                keyword, pageable.getPageNumber(), pageable.getPageSize());
        
        Page<User> userPage = userRepository.findByKeyword(keyword, pageable);
        return userPage.map(this::convertToResponse);
    }

    @Override
    public boolean existsByUsername(String username) {
        return userRepository.existsByUsername(username);
    }

    @Override
    public boolean existsByEmail(String email) {
        return userRepository.existsByEmail(email);
    }

    @Override
    @Transactional
    public UserResponse enableUser(Long id) {
        log.info("启用用户: {}", id);
        
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("用户", "ID", id));
        
        user.setStatus(1);
        User updatedUser = userRepository.save(user);
        
        log.info("用户启用成功: {}", id);
        return convertToResponse(updatedUser);
    }

    @Override
    @Transactional
    public UserResponse disableUser(Long id) {
        log.info("禁用用户: {}", id);
        
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("用户", "ID", id));
        
        user.setStatus(0);
        User updatedUser = userRepository.save(user);
        
        log.info("用户禁用成功: {}", id);
        return convertToResponse(updatedUser);
    }

    /**
     * 将User实体转换为UserResponse
     * 
     * @param user 用户实体
     * @return 用户响应DTO
     */
    private UserResponse convertToResponse(User user) {
        UserResponse response = new UserResponse();
        BeanUtils.copyProperties(user, response);
        // 不复制密码字段，确保安全性
        return response;
    }

}