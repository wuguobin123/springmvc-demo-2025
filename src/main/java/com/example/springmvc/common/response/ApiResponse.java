package com.example.springmvc.common.response;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * 统一响应结果封装类
 * 
 * 用于统一API响应格式，包含：
 * - 响应状态码
 * - 响应消息
 * - 响应数据
 * 
 * @param <T> 响应数据类型
 * @author example
 * @version 1.0.0
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApiResponse<T> {

    /**
     * 响应状态码
     */
    private Integer code;

    /**
     * 响应消息
     */
    private String message;

    /**
     * 响应数据
     */
    private T data;

    /**
     * 请求时间戳
     */
    private Long timestamp;

    /**
     * 构造成功响应
     * 
     * @param data 响应数据
     * @param <T> 数据类型
     * @return 成功响应
     */
    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(200, "操作成功", data, System.currentTimeMillis());
    }

    /**
     * 构造成功响应（无数据）
     * 
     * @return 成功响应
     */
    public static <T> ApiResponse<T> success() {
        return success(null);
    }

    /**
     * 构造成功响应（自定义消息）
     * 
     * @param message 响应消息
     * @param data 响应数据
     * @param <T> 数据类型
     * @return 成功响应
     */
    public static <T> ApiResponse<T> success(String message, T data) {
        return new ApiResponse<>(200, message, data, System.currentTimeMillis());
    }

    /**
     * 构造失败响应
     * 
     * @param code 错误码
     * @param message 错误消息
     * @param <T> 数据类型
     * @return 失败响应
     */
    public static <T> ApiResponse<T> error(Integer code, String message) {
        return new ApiResponse<>(code, message, null, System.currentTimeMillis());
    }

    /**
     * 构造失败响应（使用默认错误码500）
     * 
     * @param message 错误消息
     * @param <T> 数据类型
     * @return 失败响应
     */
    public static <T> ApiResponse<T> error(String message) {
        return error(500, message);
    }

    /**
     * 构造参数错误响应
     * 
     * @param message 错误消息
     * @param <T> 数据类型
     * @return 参数错误响应
     */
    public static <T> ApiResponse<T> badRequest(String message) {
        return error(400, message);
    }

    /**
     * 构造未授权响应
     * 
     * @param message 错误消息
     * @param <T> 数据类型
     * @return 未授权响应
     */
    public static <T> ApiResponse<T> unauthorized(String message) {
        return error(401, message);
    }

    /**
     * 构造禁止访问响应
     * 
     * @param message 错误消息
     * @param <T> 数据类型
     * @return 禁止访问响应
     */
    public static <T> ApiResponse<T> forbidden(String message) {
        return error(403, message);
    }

    /**
     * 构造未找到响应
     * 
     * @param message 错误消息
     * @param <T> 数据类型
     * @return 未找到响应
     */
    public static <T> ApiResponse<T> notFound(String message) {
        return error(404, message);
    }

}