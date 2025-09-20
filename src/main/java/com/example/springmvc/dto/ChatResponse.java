package com.example.springmvc.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 聊天响应DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ChatResponse {
    
    /**
     * AI生成的回复内容
     */
    private String content;
    
    /**
     * 使用的模型名称
     */
    private String model;
    
    /**
     * 消耗的token数量
     */
    private Integer totalTokens;
    
    /**
     * 完成原因
     */
    private String finishReason;
}