package com.example.springmvc.common.exception;

/**
 * 业务异常基类
 * 
 * 用于表示业务逻辑中的异常情况
 * 
 * @author example
 * @version 1.0.0
 */
public class BusinessException extends RuntimeException {

    /**
     * 错误码
     */
    private Integer code;

    public BusinessException(String message) {
        super(message);
        this.code = 500;
    }

    public BusinessException(Integer code, String message) {
        super(message);
        this.code = code;
    }

    public BusinessException(String message, Throwable cause) {
        super(message, cause);
        this.code = 500;
    }

    public BusinessException(Integer code, String message, Throwable cause) {
        super(message, cause);
        this.code = code;
    }

    public Integer getCode() {
        return code;
    }

    public void setCode(Integer code) {
        this.code = code;
    }

}