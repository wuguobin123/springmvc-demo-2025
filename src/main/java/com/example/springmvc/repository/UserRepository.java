package com.example.springmvc.repository;

import com.example.springmvc.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * 用户数据访问层接口
 * 
 * 继承JpaRepository获得基本的CRUD操作
 * 定义业务相关的查询方法
 * 
 * @author example
 * @version 1.0.0
 */
@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    /**
     * 根据用户名查找用户
     * 
     * @param username 用户名
     * @return 用户信息
     */
    Optional<User> findByUsername(String username);

    /**
     * 根据邮箱查找用户
     * 
     * @param email 邮箱
     * @return 用户信息
     */
    Optional<User> findByEmail(String email);

    /**
     * 根据用户名或邮箱查找用户
     * 
     * @param username 用户名
     * @param email 邮箱
     * @return 用户信息
     */
    Optional<User> findByUsernameOrEmail(String username, String email);

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
     * 根据状态查找用户列表
     * 
     * @param status 用户状态
     * @return 用户列表
     */
    List<User> findByStatus(Integer status);

    /**
     * 根据状态分页查找用户
     * 
     * @param status 用户状态
     * @param pageable 分页信息
     * @return 分页用户列表
     */
    Page<User> findByStatus(Integer status, Pageable pageable);

    /**
     * 根据真实姓名模糊查询
     * 
     * @param realName 真实姓名
     * @param pageable 分页信息
     * @return 分页用户列表
     */
    Page<User> findByRealNameContaining(String realName, Pageable pageable);

    /**
     * 使用JPQL查询 - 根据关键字搜索用户
     * 支持用户名、邮箱、真实姓名模糊查询
     * 
     * @param keyword 搜索关键字
     * @param pageable 分页信息
     * @return 分页用户列表
     */
    @Query("SELECT u FROM User u WHERE " +
           "u.username LIKE %:keyword% OR " +
           "u.email LIKE %:keyword% OR " +
           "u.realName LIKE %:keyword%")
    Page<User> findByKeyword(@Param("keyword") String keyword, Pageable pageable);

    /**
     * 使用原生SQL查询 - 统计不同状态的用户数量
     * 
     * @return 状态统计结果
     */
    @Query(value = "SELECT status, COUNT(*) as count FROM users GROUP BY status", nativeQuery = true)
    List<Object[]> countUsersByStatus();

}