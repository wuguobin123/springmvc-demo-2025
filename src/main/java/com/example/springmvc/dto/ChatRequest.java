package com.example.springmvc.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 聊天请求DTO
 */
@Data
public class ChatRequest {
    
    @NotBlank(message = "消息内容不能为空")
    private String message;
    
    /**
     * 可选的模型名称，如果不指定则使用配置的默认模型
     */
    private String model;
    
    /**
     * 温度参数，控制回复的随机性，范围0-1
     */
    private Double temperature;
    
    /**
     * 最大token数
     */
    private Integer maxTokens;
}