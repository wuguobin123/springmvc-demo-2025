package com.example.springmvc.common.utils;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * 密码工具类
 * 
 * 提供密码加密、验证等功能
 * 
 * @author example
 * @version 1.0.0
 */
public class PasswordUtil {

    private static final String SALT = "SpringMVC_Demo_Salt";

    /**
     * 加密密码
     * 
     * @param password 原始密码
     * @return 加密后的密码
     */
    public static String encryptPassword(String password) {
        if (password == null || password.isEmpty()) {
            throw new IllegalArgumentException("密码不能为空");
        }
        
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            String saltedPassword = password + SALT;
            byte[] hash = md.digest(saltedPassword.getBytes());
            
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) {
                    hexString.append('0');
                }
                hexString.append(hex);
            }
            
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("密码加密失败", e);
        }
    }

    /**
     * 验证密码
     * 
     * @param rawPassword 原始密码
     * @param encryptedPassword 加密密码
     * @return 是否匹配
     */
    public static boolean verifyPassword(String rawPassword, String encryptedPassword) {
        if (rawPassword == null || encryptedPassword == null) {
            return false;
        }
        
        String encrypted = encryptPassword(rawPassword);
        return encrypted.equals(encryptedPassword);
    }

}