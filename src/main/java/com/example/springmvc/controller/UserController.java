package com.example.springmvc.controller;

import com.example.springmvc.common.response.ApiResponse;
import com.example.springmvc.common.response.PageResponse;
import com.example.springmvc.dto.UserCreateRequest;
import com.example.springmvc.dto.UserResponse;
import com.example.springmvc.dto.UserUpdateRequest;
import com.example.springmvc.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import javax.validation.constraints.Min;
import java.util.List;

/**
 * 用户控制层
 * 
 * 处理用户相关的HTTP请求
 * 提供RESTful API接口
 * 
 * @author example
 * @version 1.0.0
 */
@Slf4j
@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
@Validated
public class UserController {

    private final UserService userService;

    /**
     * 创建用户
     * 
     * @param request 用户创建请求
     * @return 创建的用户信息
     */
    @PostMapping
    public ResponseEntity<ApiResponse<UserResponse>> createUser(@Valid @RequestBody UserCreateRequest request) {
        log.info("接收创建用户请求: {}", request.getUsername());
        
        UserResponse userResponse = userService.createUser(request);
        
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("用户创建成功", userResponse));
    }

    /**
     * 根据ID获取用户信息
     * 
     * @param id 用户ID
     * @return 用户信息
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<UserResponse>> getUserById(@PathVariable @Min(1) Long id) {
        log.info("接收获取用户请求: {}", id);
        
        UserResponse userResponse = userService.getUserById(id);
        
        return ResponseEntity.ok(ApiResponse.success(userResponse));
    }

    /**
     * 根据用户名获取用户信息
     * 
     * @param username 用户名
     * @return 用户信息
     */
    @GetMapping("/username/{username}")
    public ResponseEntity<ApiResponse<UserResponse>> getUserByUsername(@PathVariable String username) {
        log.info("接收根据用户名获取用户请求: {}", username);
        
        UserResponse userResponse = userService.getUserByUsername(username);
        
        return ResponseEntity.ok(ApiResponse.success(userResponse));
    }

    /**
     * 更新用户信息
     * 
     * @param id 用户ID
     * @param request 更新请求
     * @return 更新后的用户信息
     */
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<UserResponse>> updateUser(
            @PathVariable @Min(1) Long id,
            @Valid @RequestBody UserUpdateRequest request) {
        log.info("接收更新用户请求: {}", id);
        
        UserResponse userResponse = userService.updateUser(id, request);
        
        return ResponseEntity.ok(ApiResponse.success("用户更新成功", userResponse));
    }

    /**
     * 删除用户
     * 
     * @param id 用户ID
     * @return 删除结果
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<String>> deleteUser(@PathVariable @Min(1) Long id) {
        log.info("接收删除用户请求: {}", id);
        
        userService.deleteUser(id);
        
        return ResponseEntity.ok(ApiResponse.success("用户删除成功"));
    }

    /**
     * 获取所有用户列表
     * 
     * @return 用户列表
     */
    @GetMapping("/all")
    public ResponseEntity<ApiResponse<List<UserResponse>>> getAllUsers() {
        log.info("接收获取所有用户请求");
        
        List<UserResponse> users = userService.getAllUsers();
        
        return ResponseEntity.ok(ApiResponse.success(users));
    }

    /**
     * 分页获取用户列表
     * 
     * @param page 页码（从0开始）
     * @param size 每页大小
     * @param sort 排序字段
     * @param direction 排序方向
     * @return 分页用户列表
     */
    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<UserResponse>>> getUsers(
            @RequestParam(defaultValue = "0") @Min(0) Integer page,
            @RequestParam(defaultValue = "10") @Min(1) Integer size,
            @RequestParam(defaultValue = "id") String sort,
            @RequestParam(defaultValue = "asc") String direction) {
        log.info("接收分页获取用户请求: page={}, size={}, sort={}, direction={}", page, size, sort, direction);
        
        Sort.Direction sortDirection = "desc".equalsIgnoreCase(direction) ? 
                Sort.Direction.DESC : Sort.Direction.ASC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(sortDirection, sort));
        
        Page<UserResponse> userPage = userService.getUsers(pageable);
        PageResponse<UserResponse> pageResponse = PageResponse.of(userPage);
        
        return ResponseEntity.ok(ApiResponse.success(pageResponse));
    }

    /**
     * 根据状态分页获取用户列表
     * 
     * @param status 用户状态
     * @param page 页码
     * @param size 每页大小
     * @return 分页用户列表
     */
    @GetMapping("/status/{status}")
    public ResponseEntity<ApiResponse<PageResponse<UserResponse>>> getUsersByStatus(
            @PathVariable Integer status,
            @RequestParam(defaultValue = "0") @Min(0) Integer page,
            @RequestParam(defaultValue = "10") @Min(1) Integer size) {
        log.info("接收根据状态分页获取用户请求: status={}, page={}, size={}", status, page, size);
        
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<UserResponse> userPage = userService.getUsersByStatus(status, pageable);
        PageResponse<UserResponse> pageResponse = PageResponse.of(userPage);
        
        return ResponseEntity.ok(ApiResponse.success(pageResponse));
    }

    /**
     * 搜索用户
     * 
     * @param keyword 搜索关键字
     * @param page 页码
     * @param size 每页大小
     * @return 搜索结果
     */
    @GetMapping("/search")
    public ResponseEntity<ApiResponse<PageResponse<UserResponse>>> searchUsers(
            @RequestParam String keyword,
            @RequestParam(defaultValue = "0") @Min(0) Integer page,
            @RequestParam(defaultValue = "10") @Min(1) Integer size) {
        log.info("接收搜索用户请求: keyword={}, page={}, size={}", keyword, page, size);
        
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<UserResponse> userPage = userService.searchUsers(keyword, pageable);
        PageResponse<UserResponse> pageResponse = PageResponse.of(userPage);
        
        return ResponseEntity.ok(ApiResponse.success(pageResponse));
    }

    /**
     * 检查用户名是否存在
     * 
     * @param username 用户名
     * @return 是否存在
     */
    @GetMapping("/check/username")
    public ResponseEntity<ApiResponse<Boolean>> checkUsername(@RequestParam String username) {
        log.info("接收检查用户名请求: {}", username);
        
        boolean exists = userService.existsByUsername(username);
        
        return ResponseEntity.ok(ApiResponse.success(exists));
    }

    /**
     * 检查邮箱是否存在
     * 
     * @param email 邮箱
     * @return 是否存在
     */
    @GetMapping("/check/email")
    public ResponseEntity<ApiResponse<Boolean>> checkEmail(@RequestParam String email) {
        log.info("接收检查邮箱请求: {}", email);
        
        boolean exists = userService.existsByEmail(email);
        
        return ResponseEntity.ok(ApiResponse.success(exists));
    }

    /**
     * 启用用户
     * 
     * @param id 用户ID
     * @return 更新后的用户信息
     */
    @PostMapping("/{id}/enable")
    public ResponseEntity<ApiResponse<UserResponse>> enableUser(@PathVariable @Min(1) Long id) {
        log.info("接收启用用户请求: {}", id);
        
        UserResponse userResponse = userService.enableUser(id);
        
        return ResponseEntity.ok(ApiResponse.success("用户启用成功", userResponse));
    }

    /**
     * 禁用用户
     * 
     * @param id 用户ID
     * @return 更新后的用户信息
     */
    @PostMapping("/{id}/disable")
    public ResponseEntity<ApiResponse<UserResponse>> disableUser(@PathVariable @Min(1) Long id) {
        log.info("接收禁用用户请求: {}", id);
        
        UserResponse userResponse = userService.disableUser(id);
        
        return ResponseEntity.ok(ApiResponse.success("用户禁用成功", userResponse));
    }

}