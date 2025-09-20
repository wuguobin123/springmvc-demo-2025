package com.example.springmvc.controller;

import com.example.springmvc.common.response.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * 健康检查控制器
 * 
 * 提供应用状态检查接口
 * 
 * @author example
 * @version 1.0.0
 */
@RestController
@RequestMapping("/health")
public class HealthController {

    /**
     * 健康检查接口
     * 
     * @return 应用状态信息
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> health() {
        Map<String, Object> healthInfo = new HashMap<>();
        healthInfo.put("status", "UP");
        healthInfo.put("timestamp", LocalDateTime.now());
        healthInfo.put("application", "SpringMVC Demo");
        healthInfo.put("version", "1.0.0");
        
        return ResponseEntity.ok(ApiResponse.success("应用运行正常", healthInfo));
    }

}