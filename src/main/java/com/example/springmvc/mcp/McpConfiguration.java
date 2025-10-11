package com.example.springmvc.mcp;

import com.example.springmvc.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.modelcontextprotocol.spec.McpSchema;
import io.modelcontextprotocol.server.McpServerFeatures;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.script.ScriptEngine;
import javax.script.ScriptEngineManager;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * MCP Server 工具配置类
 * 基于 Spring AI 实现 MCP (Model Context Protocol) 服务器
 * 
 * 参考文档：
 * - Spring AI MCP Server: https://docs.spring.io/spring-ai/reference/api/mcp-server.html
 * - MCP 协议规范: https://spec.modelcontextprotocol.io/
 * 
 * @author SpringMVC Demo
 * @version 1.0.0
 */
@Configuration
public class McpConfiguration {
    
    private static final Logger logger = LoggerFactory.getLogger(McpConfiguration.class);
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private ObjectMapper objectMapper;

    /**
     * 工具1: 数据库用户查询工具
     * 从数据库中根据ID查询真实用户信息
     */
    @Bean
    public McpServerFeatures.SyncToolSpecification getUserByIdTool() {
        logger.info("正在注册 MCP 工具: getUserById");
        
        var inputSchema = new McpSchema.JsonSchema(
                "object",
                Map.of(
                        "userId", (Object) Map.of(
                                "type", "number",
                                "description", "用户ID（数字类型）"
                        )
                ),
                List.of("userId"),
                false,
                null,
                null
        );

        var tool = new McpSchema.Tool(
                "getUserById",
                "从数据库中根据用户ID查询用户信息。返回用户的详细信息，包括用户名、真实姓名、邮箱、手机号、状态等。",
                inputSchema
        );

        return new McpServerFeatures.SyncToolSpecification(
                tool,
                (exchange, arguments) -> {
                    try {
                        logger.debug("调用 getUserById 工具，参数: {}", arguments);
                        
                        // 获取参数（支持多种类型）
                        Object userIdObj = arguments.get("userId");
                        Long userId;
                        if (userIdObj instanceof Number) {
                            userId = ((Number) userIdObj).longValue();
                        } else if (userIdObj instanceof String) {
                            userId = Long.parseLong((String) userIdObj);
                        } else {
                            throw new IllegalArgumentException("userId 必须是数字类型");
                        }
                        
                        // 从数据库查询用户
                        var userOpt = userRepository.findById(userId);
                        
                        if (userOpt.isEmpty()) {
                            String errorMsg = String.format("未找到ID为 %d 的用户", userId);
                            logger.warn(errorMsg);
                            return new McpSchema.CallToolResult(
                                    List.of(new McpSchema.TextContent(errorMsg)),
                                    true  // isError
                            );
                        }
                        
                        // 将用户对象转换为JSON
                        var user = userOpt.get();
                        Map<String, Object> userMap = new HashMap<>();
                        userMap.put("id", user.getId());
                        userMap.put("username", user.getUsername());
                        userMap.put("realName", user.getRealName());
                        userMap.put("email", user.getEmail());
                        userMap.put("phone", user.getPhone());
                        userMap.put("status", user.getStatus());
                        userMap.put("createdAt", user.getCreatedAt().toString());
                        userMap.put("updatedAt", user.getUpdatedAt().toString());
                        
                        String result = objectMapper.writeValueAsString(userMap);
                        logger.debug("查询成功，返回用户: {}", result);
                        
                        return new McpSchema.CallToolResult(
                                List.of(new McpSchema.TextContent(result)),
                                false
                        );
                    } catch (Exception e) {
                        logger.error("getUserById 工具执行失败", e);
                        return new McpSchema.CallToolResult(
                                List.of(new McpSchema.TextContent("查询失败: " + e.getMessage())),
                                true
                        );
                    }
                }
        );
    }

    /**
     * 工具2: 用户列表查询工具
     * 查询所有用户或分页查询
     */
    @Bean
    public McpServerFeatures.SyncToolSpecification listUsersTool() {
        logger.info("正在注册 MCP 工具: listUsers");
        
        var inputSchema = new McpSchema.JsonSchema(
                "object",
                Map.of(
                        "limit", (Object) Map.of(
                                "type", "number",
                                "description", "返回的最大用户数量，默认10",
                                "default", 10
                        )
                ),
                List.of(),  // limit是可选参数
                false,
                null,
                null
        );

        var tool = new McpSchema.Tool(
                "listUsers",
                "查询数据库中的所有用户列表。可以指定返回的最大数量。",
                inputSchema
        );

        return new McpServerFeatures.SyncToolSpecification(
                tool,
                (exchange, arguments) -> {
                    try {
                        logger.debug("调用 listUsers 工具，参数: {}", arguments);
                        
                        int limit = 10;
                        if (arguments.containsKey("limit")) {
                            Object limitObj = arguments.get("limit");
                            if (limitObj instanceof Number) {
                                limit = ((Number) limitObj).intValue();
                            }
                        }
                        
                        // 查询所有用户
                        var users = userRepository.findAll();
                        
                        // 限制返回数量
                        var limitedUsers = users.stream()
                                .limit(limit)
                                .map(user -> {
                                    Map<String, Object> userMap = new HashMap<>();
                                    userMap.put("id", user.getId());
                                    userMap.put("username", user.getUsername());
                                    userMap.put("realName", user.getRealName());
                                    userMap.put("email", user.getEmail());
                                    userMap.put("status", user.getStatus());
                                    return userMap;
                                })
                                .toList();
                        
                        Map<String, Object> response = new HashMap<>();
                        response.put("total", users.size());
                        response.put("returned", limitedUsers.size());
                        response.put("users", limitedUsers);
                        
                        String result = objectMapper.writeValueAsString(response);
                        logger.debug("查询成功，返回 {} 个用户", limitedUsers.size());
                        
                        return new McpSchema.CallToolResult(
                                List.of(new McpSchema.TextContent(result)),
                                false
                        );
                    } catch (Exception e) {
                        logger.error("listUsers 工具执行失败", e);
                        return new McpSchema.CallToolResult(
                                List.of(new McpSchema.TextContent("查询失败: " + e.getMessage())),
                                true
                        );
                    }
                }
        );
    }

    /**
     * 工具3: 数学计算器工具
     * 支持基本的数学表达式计算
     */
    @Bean
    public McpServerFeatures.SyncToolSpecification calculatorTool() {
        logger.info("正在注册 MCP 工具: calculator");
        
        var inputSchema = new McpSchema.JsonSchema(
                "object",
                Map.of(
                        "expression", (Object) Map.of(
                                "type", "string",
                                "description", "数学表达式，支持 +、-、*、/、()，例如: (2+3)*4"
                        )
                ),
                List.of("expression"),
                false,
                null,
                null
        );

        var tool = new McpSchema.Tool(
                "calculator",
                "计算数学表达式。支持加减乘除和括号运算。",
                inputSchema
        );

        return new McpServerFeatures.SyncToolSpecification(
                tool,
                (exchange, arguments) -> {
                    try {
                        String expression = (String) arguments.get("expression");
                        logger.debug("计算表达式: {}", expression);
                        
                        // 使用 JavaScript 引擎计算表达式
                        ScriptEngineManager manager = new ScriptEngineManager();
                        ScriptEngine engine = manager.getEngineByName("JavaScript");
                        
                        // 验证表达式安全性（只允许数字和运算符）
                        if (!expression.matches("[0-9+\\-*/().\\s]+")) {
                            throw new IllegalArgumentException("表达式包含非法字符");
                        }
                        
                        Object result = engine.eval(expression);
                        
                        Map<String, Object> response = new HashMap<>();
                        response.put("expression", expression);
                        response.put("result", result);
                        
                        String resultJson = objectMapper.writeValueAsString(response);
                        logger.debug("计算结果: {}", resultJson);
                        
                        return new McpSchema.CallToolResult(
                                List.of(new McpSchema.TextContent(resultJson)),
                                false
                        );
                    } catch (Exception e) {
                        logger.error("calculator 工具执行失败", e);
                        return new McpSchema.CallToolResult(
                                List.of(new McpSchema.TextContent("计算失败: " + e.getMessage())),
                                true
                        );
                    }
                }
        );
    }
    
    /**
     * 工具4: 系统时间工具
     * 获取当前服务器时间
     */
    @Bean
    public McpServerFeatures.SyncToolSpecification getServerTimeTool() {
        logger.info("正在注册 MCP 工具: getServerTime");
        
        var inputSchema = new McpSchema.JsonSchema(
                "object",
                Map.of(
                        "format", (Object) Map.of(
                                "type", "string",
                                "description", "时间格式，可选值: iso (ISO 8601), readable (人类可读), timestamp (Unix时间戳)",
                                "default", "iso"
                        )
                ),
                List.of(),  // format是可选参数
                false,
                null,
                null
        );

        var tool = new McpSchema.Tool(
                "getServerTime",
                "获取当前服务器时间。可以指定返回格式：ISO 8601、人类可读格式或Unix时间戳。",
                inputSchema
        );

        return new McpServerFeatures.SyncToolSpecification(
                tool,
                (exchange, arguments) -> {
                    try {
                        String format = arguments.getOrDefault("format", "iso").toString();
                        LocalDateTime now = LocalDateTime.now();
                        
                        Map<String, Object> response = new HashMap<>();
                        response.put("timezone", "Asia/Shanghai");
                        
                        switch (format.toLowerCase()) {
                            case "readable":
                                response.put("time", now.format(DateTimeFormatter.ofPattern("yyyy年MM月dd日 HH:mm:ss")));
                                response.put("format", "readable");
                                break;
                            case "timestamp":
                                response.put("time", System.currentTimeMillis());
                                response.put("format", "timestamp");
                                break;
                            default:  // iso
                                response.put("time", now.toString());
                                response.put("format", "ISO 8601");
                        }
                        
                        String result = objectMapper.writeValueAsString(response);
                        logger.debug("返回服务器时间: {}", result);
                        
                        return new McpSchema.CallToolResult(
                                List.of(new McpSchema.TextContent(result)),
                                false
                        );
                    } catch (Exception e) {
                        logger.error("getServerTime 工具执行失败", e);
                        return new McpSchema.CallToolResult(
                                List.of(new McpSchema.TextContent("获取时间失败: " + e.getMessage())),
                                true
                        );
                    }
                }
        );
    }

    /**
     * 工具5: 数据库统计工具
     * 获取数据库统计信息
     */
    @Bean
    public McpServerFeatures.SyncToolSpecification getDatabaseStatsTool() {
        logger.info("正在注册 MCP 工具: getDatabaseStats");
        
        var inputSchema = new McpSchema.JsonSchema(
                "object",
                Map.of(),
                List.of(),
                false,
                null,
                null
        );

        var tool = new McpSchema.Tool(
                "getDatabaseStats",
                "获取数据库统计信息，包括用户总数、激活用户数、用户资料完整度等。",
                inputSchema
        );

        return new McpServerFeatures.SyncToolSpecification(
                tool,
                (exchange, arguments) -> {
                    try {
                        logger.debug("调用 getDatabaseStats 工具");
                        
                        var allUsers = userRepository.findAll();
                        
                        Map<String, Object> stats = new HashMap<>();
                        stats.put("totalUsers", allUsers.size());
                        
                        if (!allUsers.isEmpty()) {
                            // 统计激活用户数
                            long activeUsers = allUsers.stream()
                                    .filter(u -> u.getStatus() == 1)
                                    .count();
                            stats.put("activeUsers", activeUsers);
                            stats.put("inactiveUsers", allUsers.size() - activeUsers);
                            
                            // 统计有真实姓名的用户数
                            long usersWithRealName = allUsers.stream()
                                    .filter(u -> u.getRealName() != null && !u.getRealName().isEmpty())
                                    .count();
                            stats.put("usersWithRealName", usersWithRealName);
                            
                            // 统计有手机号的用户数
                            long usersWithPhone = allUsers.stream()
                                    .filter(u -> u.getPhone() != null && !u.getPhone().isEmpty())
                                    .count();
                            stats.put("usersWithPhone", usersWithPhone);
                        }
                        
                        String result = objectMapper.writeValueAsString(stats);
                        logger.debug("统计结果: {}", result);
                        
                        return new McpSchema.CallToolResult(
                                List.of(new McpSchema.TextContent(result)),
                                false
                        );
                    } catch (Exception e) {
                        logger.error("getDatabaseStats 工具执行失败", e);
                        return new McpSchema.CallToolResult(
                                List.of(new McpSchema.TextContent("获取统计信息失败: " + e.getMessage())),
                                true
                        );
                    }
                }
        );
    }
}