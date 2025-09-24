package com.example.springmvc.service.impl;

import com.example.springmvc.dto.ChatRequest;
import com.example.springmvc.dto.ChatResponse;
import com.example.springmvc.service.AiChatService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;

/**
 * AI聊天服务实现类
 */
@Service
public class AiChatServiceImpl implements AiChatService {

    private final ChatModel chatModel;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${spring.ai.openai.api-key}")
    private String apiKey;

    @Value("${spring.ai.openai.base-url}")
    private String baseUrl;
    
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

    @Override
    public SseEmitter streamChat(String message) {
        SseEmitter emitter = new SseEmitter(0L);
        new Thread(() -> {
            HttpURLConnection connection = null;
            try {
                String api = baseUrl + "/chat/completions";
                URL url = new URL(api);
                connection = (HttpURLConnection) url.openConnection();
                connection.setRequestMethod("POST");
                connection.setRequestProperty("Authorization", "Bearer " + apiKey);
                connection.setRequestProperty("Content-Type", "application/json");
                connection.setRequestProperty("Accept", "application/json");
                connection.setDoOutput(true);

                String payload = "{" +
                        "\"model\":\"deepseek-ai/DeepSeek-V2.5\"," +
                        "\"messages\":[{" +
                        "\"role\":\"user\",\"content\":" + objectMapper.writeValueAsString(message) +
                        "}]," +
                        "\"stream\":true}";

                connection.getOutputStream().write(payload.getBytes(StandardCharsets.UTF_8));
                connection.getOutputStream().flush();

                int code = connection.getResponseCode();
                InputStream inputStream = code >= 200 && code < 300 ? connection.getInputStream() : connection.getErrorStream();
                if (inputStream == null) {
                    emitter.completeWithError(new IllegalStateException("No response stream"));
                    return;
                }

                try (BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream, StandardCharsets.UTF_8))) {
                    String line;
                    while ((line = reader.readLine()) != null) {
                        if (line.isEmpty()) continue;
                        if (line.startsWith("data: ")) {
                            String json = line.substring(6).trim();
                            if ("[DONE]".equals(json)) {
                                break;
                            }
                            JsonNode node = objectMapper.readTree(json);
                            JsonNode delta = node.path("choices").path(0).path("delta");
                            String content = delta.path("content").asText("");
                            String reasoning = delta.path("reasoning_content").asText("");
                            String token = !content.isEmpty() ? content : reasoning;
                            if (!token.isEmpty()) {
                                emitter.send(SseEmitter.event().name("token").data(token));
                            }
                        }
                    }
                }
                emitter.complete();
            } catch (Exception e) {
                try {
                    emitter.send(SseEmitter.event().name("error").data(e.getMessage()));
                } catch (Exception ignore) {}
                emitter.completeWithError(e);
            } finally {
                if (connection != null) {
                    connection.disconnect();
                }
            }
        }).start();
        return emitter;
    }
}