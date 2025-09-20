package com.example.springmvc.config;

import io.github.cdimascio.dotenv.Dotenv;
import jakarta.annotation.PostConstruct;
import org.springframework.context.annotation.Configuration;

/**
 * .env文件加载配置
 * 用于在应用启动时加载.env文件中的环境变量
 */
@Configuration
public class DotenvConfig {

    @PostConstruct
    public void loadEnv() {
        try {
            Dotenv dotenv = Dotenv.configure()
                    .directory("./")  // .env文件位于项目根目录
                    .filename(".env") // 指定文件名
                    .ignoreIfMalformed()
                    .ignoreIfMissing()
                    .load();

            // 将.env中的变量设置为系统属性
            dotenv.entries().forEach(entry -> {
                String key = entry.getKey();
                String value = entry.getValue();
                // 只有当系统属性中没有该变量时才设置（允许系统环境变量优先）
                if (System.getProperty(key) == null) {
                    System.setProperty(key, value);
                }
            });

            System.out.println("✅ .env文件加载成功");
        } catch (Exception e) {
            System.err.println("⚠️ .env文件加载失败: " + e.getMessage());
            System.err.println("如果是在生产环境，请确保环境变量已正确配置");
        }
    }
}