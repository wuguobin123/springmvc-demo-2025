package com.example.springmvc.common.exception;

/**
 * 资源已存在异常
 * 
 * 当创建的资源已经存在时抛出此异常
 * 
 * @author example
 * @version 1.0.0
 */
public class ResourceExistsException extends BusinessException {

    public ResourceExistsException(String message) {
        super(409, message);
    }

    public ResourceExistsException(String resourceName, String fieldName, Object fieldValue) {
        super(409, String.format("%s已存在，%s: %s", resourceName, fieldName, fieldValue));
    }

}