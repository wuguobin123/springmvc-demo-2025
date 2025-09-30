package com.example.springmvc.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * MCP测试控制器
 * 用于验证MCP Server是否正常工作
 */
@RestController
public class McpTestController {

    /**
     * 健康检查端点
     * @return 简单的响应表示服务正在运行
     */
    @GetMapping("/mcp/health")
    public String healthCheck() {
        return "MCP Server is running";
    }
}