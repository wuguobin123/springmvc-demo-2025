package com.example.springmvc.mcp;

import io.modelcontextprotocol.spec.McpSchema;
import io.modelcontextprotocol.server.McpServerFeatures;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;
import java.util.Map;

@Configuration
public class McpConfiguration {

    /**
     * 创建一个Mock工具，用于演示MCP工具功能
     * @return 工具规范
     */
    @Bean
    public McpServerFeatures.SyncToolSpecification mockUserTool() {
        // 定义工具的参数
        var inputSchema = new McpSchema.JsonSchema(
                "object",
                Map.of(
                        "userId", Map.of(
                                "type", "string",
                                "description", "用户ID"
                        )
                ),
                List.of("userId"),
                null
        );

        // 定义工具
        var tool = new McpSchema.Tool(
                "getUserById",
                "根据用户ID获取用户信息",
                inputSchema
        );

        // 定义工具回调函数
        var toolCallback = new McpServerFeatures.SyncToolSpecification(
                tool,
                (exchange, arguments) -> {
                    // 模拟工具执行逻辑
                    String userId = (String) arguments.get("userId");
                    
                    // 构造返回结果 (模拟数据)
                    String result = String.format("{\"id\":\"%s\",\"name\":\"张三\",\"email\":\"zhangsan@example.com\",\"age\":25}", userId);
                    
                    return new McpSchema.CallToolResult(
                            List.of(new McpSchema.TextContent(result)),
                            false
                    );
                }
        );

        return toolCallback;
    }

    /**
     * 创建一个计算器工具，用于演示MCP工具功能
     * @return 工具规范
     */
    @Bean
    public McpServerFeatures.SyncToolSpecification calculatorTool() {
        // 定义工具的参数
        var inputSchema = new McpSchema.JsonSchema(
                "object",
                Map.of(
                        "expression", Map.of(
                                "type", "string",
                                "description", "数学表达式，例如: 2+3*4"
                        )
                ),
                List.of("expression"),
                null
        );

        // 定义工具
        var tool = new McpSchema.Tool(
                "calculate",
                "计算数学表达式",
                inputSchema
        );

        // 定义工具回调函数
        var toolCallback = new McpServerFeatures.SyncToolSpecification(
                tool,
                (exchange, arguments) -> {
                    String expression = (String) arguments.get("expression");
                    
                    // 模拟计算结果 (实际项目中应该使用真正的表达式解析器)
                    String result = "表达式: " + expression + ", 计算结果: 42 (模拟)";
                    
                    return new McpSchema.CallToolResult(
                            List.of(new McpSchema.TextContent(result)),
                            false
                    );
                }
        );

        return toolCallback;
    }
}