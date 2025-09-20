package com.example.springmvc.service.impl;

import com.example.springmvc.dto.ChatRequest;
import com.example.springmvc.dto.ChatResponse;
import com.example.springmvc.service.AiChatService;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.openai.OpenAiChatOptions;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

/**
 * AI聊天服务实现类
 */
@Service
public class AiChatServiceImpl implements AiChatService {

    private final ChatModel chatModel;
    
    public AiChatServiceImpl(ChatModel chatModel) {
        this.chatModel = chatModel;
    }

    @Override
    public ChatResponse chat(ChatRequest request) {
        try {
            System.out.println("发送AI聊天请求: " + request.getMessage());
            
            // 构建消息
            UserMessage userMessage = new UserMessage(request.getMessage());
            Prompt prompt = new Prompt(userMessage);
            
            // 调用AI服务
            org.springframework.ai.chat.model.ChatResponse response = chatModel.call(prompt);
            
            // 构建响应
            ChatResponse chatResponse = new ChatResponse();
            chatResponse.setContent(response.getResult().getOutput().getText());
            chatResponse.setModel("默认模型");
            chatResponse.setTotalTokens(0); // 简化处理
            chatResponse.setFinishReason("完成");
            
            System.out.println("AI聊天响应成功");
            return chatResponse;
            
        } catch (Exception e) {
            System.err.println("AI聊天请求失败: " + e.getMessage());
            throw new RuntimeException("AI聊天服务异常: " + e.getMessage(), e);
        }
    }

    @Override
    public String simpleChat(String message) {
        try {
            System.out.println("发送简单AI聊天请求: " + message);
            
            UserMessage userMessage = new UserMessage(message);
            Prompt prompt = new Prompt(userMessage);
            org.springframework.ai.chat.model.ChatResponse response = chatModel.call(prompt);
            
            String responseContent = response.getResult().getOutput().getText();
            
            System.out.println("简单AI聊天响应成功");
            return responseContent;
            
        } catch (Exception e) {
            System.err.println("简单AI聊天请求失败: " + e.getMessage());
            throw new RuntimeException("AI聊天服务异常: " + e.getMessage(), e);
        }
    }
}