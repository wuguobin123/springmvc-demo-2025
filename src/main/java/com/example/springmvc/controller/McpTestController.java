package com.example.springmvc.controller;

import io.modelcontextprotocol.server.McpServerFeatures;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * MCP 测试与监控控制器
 * 提供 MCP Server 的健康检查、工具列表、使用示例等功能
 * 
 * @author SpringMVC Demo
 * @version 1.0.0
 */
@RestController
@RequestMapping("/mcp")
public class McpTestController {

    @Autowired
    private ApplicationContext applicationContext;

    /**
     * 健康检查端点
     * GET /api/mcp/health
     * 
     * @return 健康状态信息
     */
    @GetMapping("/health")
    public Map<String, Object> healthCheck() {
        Map<String, Object> health = new LinkedHashMap<>();
        health.put("status", "UP");
        health.put("service", "MCP Server");
        health.put("version", "1.0.0");
        health.put("timestamp", LocalDateTime.now().toString());
        health.put("protocol", "MCP (Model Context Protocol)");
        health.put("endpoints", Map.of(
                "sse", "/api/mcp/sse",
                "message", "/api/mcp/message"
        ));
        return health;
    }

    /**
     * 获取已注册的工具列表
     * GET /api/mcp/debug/tools
     * 
     * @return 工具详细信息
     */
    @GetMapping("/debug/tools")
    public Map<String, Object> debugTools() {
        Map<String, McpServerFeatures.SyncToolSpecification> toolBeans = 
            applicationContext.getBeansOfType(McpServerFeatures.SyncToolSpecification.class);
        
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("totalTools", toolBeans.size());
        response.put("timestamp", LocalDateTime.now().toString());
        
        if (toolBeans.isEmpty()) {
            response.put("message", "No tools registered");
            response.put("tools", Collections.emptyList());
            return response;
        }
        
        List<Map<String, Object>> tools = toolBeans.entrySet().stream()
                .map(entry -> {
                    Map<String, Object> toolInfo = new LinkedHashMap<>();
                    toolInfo.put("beanName", entry.getKey());
                    toolInfo.put("toolName", entry.getValue().tool().name());
                    toolInfo.put("description", entry.getValue().tool().description());
                    
                    // 提取参数信息
                    var inputSchema = entry.getValue().tool().inputSchema();
                    if (inputSchema != null && inputSchema.properties() != null) {
                        toolInfo.put("parameters", inputSchema.properties().keySet());
                    } else {
                        toolInfo.put("parameters", Collections.emptyList());
                    }
                    
                    return toolInfo;
                })
                .collect(Collectors.toList());
        
        response.put("tools", tools);
        return response;
    }

    /**
     * 获取 MCP Server 使用说明
     * GET /api/mcp/docs
     * 
     * @return 使用文档
     */
    @GetMapping(value = "/docs", produces = MediaType.TEXT_PLAIN_VALUE)
    public String getDocs() {
        StringBuilder docs = new StringBuilder();
        docs.append("=".repeat(80)).append("\n");
        docs.append("MCP Server 使用文档\n");
        docs.append("=".repeat(80)).append("\n\n");
        
        docs.append("📌 什么是 MCP?\n");
        docs.append("-".repeat(80)).append("\n");
        docs.append("MCP (Model Context Protocol) 是一个开放协议，用于在 AI 应用和数据源之间建立\n");
        docs.append("标准化的连接。通过 MCP Server，AI 模型可以安全地访问您的数据和工具。\n\n");
        
        docs.append("🔗 连接信息\n");
        docs.append("-".repeat(80)).append("\n");
        docs.append("SSE 端点:     /api/mcp/sse\n");
        docs.append("消息端点:     /api/mcp/message\n");
        docs.append("健康检查:     /api/mcp/health\n");
        docs.append("工具列表:     /api/mcp/debug/tools\n");
        docs.append("使用文档:     /api/mcp/docs (本页面)\n\n");
        
        docs.append("🛠️ 已注册工具\n");
        docs.append("-".repeat(80)).append("\n");
        
        Map<String, McpServerFeatures.SyncToolSpecification> tools = 
            applicationContext.getBeansOfType(McpServerFeatures.SyncToolSpecification.class);
        
        int index = 1;
        for (var entry : tools.entrySet()) {
            var tool = entry.getValue().tool();
            docs.append(String.format("%d. %s\n", index++, tool.name()));
            docs.append(String.format("   描述: %s\n", tool.description()));
            
            var schema = tool.inputSchema();
            if (schema != null && schema.properties() != null && !schema.properties().isEmpty()) {
                docs.append("   参数:\n");
                schema.properties().forEach((paramName, paramDef) -> {
                    if (paramDef instanceof Map) {
                        @SuppressWarnings("unchecked")
                        Map<String, Object> paramMap = (Map<String, Object>) paramDef;
                        String type = String.valueOf(paramMap.get("type"));
                        String desc = String.valueOf(paramMap.get("description"));
                        boolean required = schema.required() != null && schema.required().contains(paramName);
                        docs.append(String.format("     - %s (%s)%s: %s\n", 
                                paramName, type, required ? " [必填]" : "", desc));
                    }
                });
            } else {
                docs.append("   参数: 无\n");
            }
            docs.append("\n");
        }
        
        docs.append("📖 使用示例\n");
        docs.append("-".repeat(80)).append("\n");
        docs.append("1. 建立 SSE 连接:\n");
        docs.append("   curl -N http://localhost:8080/api/mcp/sse \\\n");
        docs.append("        -H \"Accept: text/event-stream\"\n\n");
        
        docs.append("2. 调用工具 (需要先获取 session ID):\n");
        docs.append("   curl http://localhost:8080/api/mcp/message \\\n");
        docs.append("        -H \"Content-Type: application/json\" \\\n");
        docs.append("        -H \"X-Session-Id: <your-session-id>\" \\\n");
        docs.append("        -d '{\n");
        docs.append("          \"jsonrpc\": \"2.0\",\n");
        docs.append("          \"method\": \"tools/call\",\n");
        docs.append("          \"params\": {\n");
        docs.append("            \"name\": \"getUserById\",\n");
        docs.append("            \"arguments\": {\"userId\": 1}\n");
        docs.append("          },\n");
        docs.append("          \"id\": 1\n");
        docs.append("        }'\n\n");
        
        docs.append("🔧 配置客户端 (如 Claude Desktop)\n");
        docs.append("-".repeat(80)).append("\n");
        docs.append("在 Claude Desktop 的 MCP 配置中添加:\n\n");
        docs.append("{\n");
        docs.append("  \"mcpServers\": {\n");
        docs.append("    \"springmvc-demo\": {\n");
        docs.append("      \"url\": \"http://localhost:8080/api\"\n");
        docs.append("    }\n");
        docs.append("  }\n");
        docs.append("}\n\n");
        
        docs.append("=".repeat(80)).append("\n");
        docs.append("生成时间: ").append(LocalDateTime.now().toString()).append("\n");
        docs.append("=".repeat(80)).append("\n");
        
        return docs.toString();
    }

    /**
     * 获取 MCP Server 配置信息
     * GET /api/mcp/info
     * 
     * @return 配置信息
     */
    @GetMapping("/info")
    public Map<String, Object> getInfo() {
        Map<String, Object> info = new LinkedHashMap<>();
        info.put("name", "springmvc-demo-mcp-server");
        info.put("version", "1.0.0");
        info.put("protocolVersion", "2024-11-05");
        info.put("description", "Spring AI MCP Server - 演示项目");
        
        // 能力列表
        Map<String, Object> capabilities = new LinkedHashMap<>();
        capabilities.put("tools", Map.of(
                "supported", true,
                "listChanged", true
        ));
        capabilities.put("resources", Map.of(
                "supported", true,
                "subscribe", true,
                "listChanged", true
        ));
        capabilities.put("prompts", Map.of(
                "supported", true,
                "listChanged", true
        ));
        capabilities.put("completions", Map.of(
                "supported", true
        ));
        capabilities.put("logging", Map.of(
                "supported", true
        ));
        info.put("capabilities", capabilities);
        
        // 工具统计
        int toolCount = applicationContext.getBeansOfType(
                McpServerFeatures.SyncToolSpecification.class).size();
        info.put("registeredTools", toolCount);
        
        info.put("timestamp", LocalDateTime.now().toString());
        
        return info;
    }
}