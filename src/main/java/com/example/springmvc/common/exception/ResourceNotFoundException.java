package com.example.springmvc.common.exception;

/**
 * 资源未找到异常
 * 
 * 当请求的资源不存在时抛出此异常
 * 
 * @author example
 * @version 1.0.0
 */
public class ResourceNotFoundException extends BusinessException {

    public ResourceNotFoundException(String message) {
        super(404, message);
    }

    public ResourceNotFoundException(String resourceName, String fieldName, Object fieldValue) {
        super(404, String.format("%s未找到，%s: %s", resourceName, fieldName, fieldValue));
    }

}