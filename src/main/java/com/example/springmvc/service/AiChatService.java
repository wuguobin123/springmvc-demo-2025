package com.example.springmvc.service;

import com.example.springmvc.dto.ChatRequest;
import com.example.springmvc.dto.ChatResponse;

/**
 * AI聊天服务接口
 */
public interface AiChatService {
    
    /**
     * 发送聊天消息并获取AI回复
     * 
     * @param request 聊天请求
     * @return AI回复
     */
    ChatResponse chat(ChatRequest request);
    
    /**
     * 简单的文本聊天
     * 
     * @param message 用户消息
     * @return AI回复文本
     */
    String simpleChat(String message);
}