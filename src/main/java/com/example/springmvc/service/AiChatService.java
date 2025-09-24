package com.example.springmvc.service;

import com.example.springmvc.dto.ChatRequest;
import com.example.springmvc.dto.ChatResponse;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

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

    /**
     * 流式输出聊天，使用SSE返回token流
     *
     * @param message 用户消息
     * @return SseEmitter 用于服务端推送
     */
    SseEmitter streamChat(String message);
}