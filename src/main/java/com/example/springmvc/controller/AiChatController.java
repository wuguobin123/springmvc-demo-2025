package com.example.springmvc.controller;

import com.example.springmvc.common.response.ApiResponse;
import com.example.springmvc.dto.ChatRequest;
import com.example.springmvc.dto.ChatResponse;
import com.example.springmvc.service.AiChatService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

/**
 * AI聊天控制器
 */
@RestController
@RequestMapping("/ai")
public class AiChatController {

    private final AiChatService aiChatService;
    
    public AiChatController(AiChatService aiChatService) {
        this.aiChatService = aiChatService;
    }

    /**
     * AI聊天接口
     */
    @PostMapping("/chat")
    public ApiResponse<ChatResponse> chat(@Valid @RequestBody ChatRequest request) {
        System.out.println("收到AI聊天请求: " + request.getMessage());
        
        ChatResponse response = aiChatService.chat(request);
        
        return ApiResponse.success(response);
    }

    /**
     * 简单聊天接口
     */
    @PostMapping("/simple-chat")
    public ApiResponse<String> simpleChat(@RequestParam String message) {
        System.out.println("收到简单AI聊天请求: " + message);
        
        String response = aiChatService.simpleChat(message);
        
        return ApiResponse.success(response);
    }

    /**
     * 健康检查
     */
    @GetMapping("/health")
    public ApiResponse<String> health() {
        return ApiResponse.success("AI服务运行正常");
    }
}