package com.example.springmvc.service;

import com.example.springmvc.dto.UserCreateRequest;
import com.example.springmvc.dto.UserResponse;
import com.example.springmvc.dto.UserUpdateRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

/**
 * 用户业务逻辑层接口
 * 
 * 定义用户相关的业务操作
 * 提供事务支持和业务逻辑处理
 * 
 * @author example
 * @version 1.0.0
 */
public interface UserService {

    /**
     * 创建用户
     * 
     * @param request 用户创建请求
     * @return 创建的用户信息
     */
    UserResponse createUser(UserCreateRequest request);

    /**
     * 根据ID获取用户信息
     * 
     * @param id 用户ID
     * @return 用户信息
     */
    UserResponse getUserById(Long id);

    /**
     * 根据用户名获取用户信息
     * 
     * @param username 用户名
     * @return 用户信息
     */
    UserResponse getUserByUsername(String username);

    /**
     * 更新用户信息
     * 
     * @param id 用户ID
     * @param request 更新请求
     * @return 更新后的用户信息
     */
    UserResponse updateUser(Long id, UserUpdateRequest request);

    /**
     * 删除用户
     * 
     * @param id 用户ID
     */
    void deleteUser(Long id);

    /**
     * 获取所有用户列表
     * 
     * @return 用户列表
     */
    List<UserResponse> getAllUsers();

    /**
     * 分页获取用户列表
     * 
     * @param pageable 分页信息
     * @return 分页用户列表
     */
    Page<UserResponse> getUsers(Pageable pageable);

    /**
     * 根据状态分页获取用户列表
     * 
     * @param status 用户状态
     * @param pageable 分页信息
     * @return 分页用户列表
     */
    Page<UserResponse> getUsersByStatus(Integer status, Pageable pageable);

    /**
     * 根据关键字搜索用户
     * 
     * @param keyword 搜索关键字
     * @param pageable 分页信息
     * @return 分页用户列表
     */
    Page<UserResponse> searchUsers(String keyword, Pageable pageable);

    /**
     * 检查用户名是否存在
     * 
     * @param username 用户名
     * @return 是否存在
     */
    boolean existsByUsername(String username);

    /**
     * 检查邮箱是否存在
     * 
     * @param email 邮箱
     * @return 是否存在
     */
    boolean existsByEmail(String email);

    /**
     * 启用用户
     * 
     * @param id 用户ID
     * @return 更新后的用户信息
     */
    UserResponse enableUser(Long id);

    /**
     * 禁用用户
     * 
     * @param id 用户ID
     * @return 更新后的用户信息
     */
    UserResponse disableUser(Long id);

}