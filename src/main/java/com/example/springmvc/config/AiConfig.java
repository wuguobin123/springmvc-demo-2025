package com.example.springmvc.config;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

/**
 * AI配置类
 */
@Configuration
public class AiConfig {

    @Value("${spring.ai.openai.api-key}")
    private String apiKey;

    @Value("${spring.ai.openai.base-url}")
    private String baseUrl;

    @jakarta.annotation.PostConstruct
    public void init() {
        System.out.println("🔍 AI配置初始化:");
        System.out.println("🔑 API Key: " + (apiKey != null && !apiKey.isEmpty() ? "已设置 (长度: " + apiKey.length() + ")" : "未设置或为空"));
        System.out.println("🌐 Base URL: " + baseUrl);
        System.out.println("🔍 系统属性 SILICONFLOW_API_KEY: " + System.getProperty("SILICONFLOW_API_KEY"));
        System.out.println("🔍 环境变量 SILICONFLOW_API_KEY: " + System.getenv("SILICONFLOW_API_KEY"));
    }

    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }

    /**
     * 提供ChatModel bean，使用真实的SiliconFlow API
     */
    @Bean
    public ChatModel chatModel(RestTemplate restTemplate) {
        return new SiliconFlowChatModel(apiKey, baseUrl, restTemplate);
    }

    /**
     * SiliconFlow API实现的ChatModel
     */
    private static class SiliconFlowChatModel implements ChatModel {
        private final String apiKey;
        private final String baseUrl;
        private final RestTemplate restTemplate;
        private final ObjectMapper objectMapper;

        public SiliconFlowChatModel(String apiKey, String baseUrl, RestTemplate restTemplate) {
            this.apiKey = apiKey;
            this.baseUrl = baseUrl;
            this.restTemplate = restTemplate;
            this.objectMapper = new ObjectMapper();
        }

        @Override
        public org.springframework.ai.chat.model.ChatResponse call(org.springframework.ai.chat.prompt.Prompt prompt) {
            try {
                // 获取用户输入的消息
                String userMessage = prompt.getInstructions().get(0).getText();

                // 构建请求头，按照SiliconFlow API规范
                HttpHeaders headers = new HttpHeaders();
                headers.set("Authorization", "Bearer " + apiKey);
                headers.set("Content-Type", "application/json");

                // 构建请求体，按照OpenAI兼容格式
                SiliconFlowRequest requestBody = new SiliconFlowRequest();
                requestBody.model = "Qwen/QwQ-32B";
                requestBody.messages = List.of(new SiliconFlowMessage("user", userMessage));
                requestBody.temperature = 0.7;
                requestBody.maxTokens = 1000;

                String requestJson = objectMapper.writeValueAsString(requestBody);
                HttpEntity<String> entity = new HttpEntity<>(requestJson, headers);

                // 调用SiliconFlow API
                String apiUrl = baseUrl + "/chat/completions";
                ResponseEntity<String> response = restTemplate.exchange(
                    apiUrl, HttpMethod.POST, entity, String.class);

                // 解析响应
                if (response.getStatusCode().is2xxSuccessful()) {
                    SiliconFlowResponse siliconFlowResponse = objectMapper.readValue(
                        response.getBody(), SiliconFlowResponse.class);
                    
                    String responseContent = siliconFlowResponse.choices.get(0).message.content;
                    
                    return new org.springframework.ai.chat.model.ChatResponse(
                        List.of(
                            new org.springframework.ai.chat.model.Generation(
                                new org.springframework.ai.chat.messages.AssistantMessage(responseContent)
                            )
                        )
                    );
                } else {
                    // API调用失败，返回错误信息
                    String errorMessage = "抱歉，AI服务暂时不可用。错误代码：" + response.getStatusCode();
                    return new org.springframework.ai.chat.model.ChatResponse(
                        List.of(
                            new org.springframework.ai.chat.model.Generation(
                                new org.springframework.ai.chat.messages.AssistantMessage(errorMessage)
                            )
                        )
                    );
                }
            } catch (Exception e) {
                // 异常处理
                String errorMessage = "抱歉，AI服务出现错误：" + e.getMessage();
                return new org.springframework.ai.chat.model.ChatResponse(
                    List.of(
                        new org.springframework.ai.chat.model.Generation(
                            new org.springframework.ai.chat.messages.AssistantMessage(errorMessage)
                        )
                    )
                );
            }
        }
    }

    // SiliconFlow API请求的DTO类
    private static class SiliconFlowRequest {
        public String model;
        public List<SiliconFlowMessage> messages;
        public double temperature;
        @JsonProperty("max_tokens")
        public int maxTokens;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class SiliconFlowMessage {
        public String role;
        public String content;

        public SiliconFlowMessage() {}

        public SiliconFlowMessage(String role, String content) {
            this.role = role;
            this.content = content;
        }
    }

    // SiliconFlow API响应的DTO类
    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class SiliconFlowResponse {
        public List<SiliconFlowChoice> choices;
        public SiliconFlowUsage usage;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class SiliconFlowChoice {
        public SiliconFlowMessage message;
        @JsonProperty("finish_reason")
        public String finishReason;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class SiliconFlowUsage {
        @JsonProperty("prompt_tokens")
        public int promptTokens;
        @JsonProperty("completion_tokens")
        public int completionTokens;
        @JsonProperty("total_tokens")
        public int totalTokens;
    }
}