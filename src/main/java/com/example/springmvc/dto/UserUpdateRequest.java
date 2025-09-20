package com.example.springmvc.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import javax.validation.constraints.Email;
import javax.validation.constraints.Size;

/**
 * 用户更新请求DTO
 * 
 * 用于接收前端更新用户的请求参数
 * 更新操作中的字段都是可选的
 * 
 * @author example
 * @version 1.0.0
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserUpdateRequest {

    /**
     * 邮箱
     */
    @Email(message = "邮箱格式不正确")
    private String email;

    /**
     * 真实姓名
     */
    private String realName;

    /**
     * 手机号
     */
    private String phone;

    /**
     * 用户状态：0-禁用，1-启用
     */
    private Integer status;

}