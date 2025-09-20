package com.example.springmvc;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.amqp.RabbitAutoConfiguration;
import org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration;

/**
 * Spring Boot 应用启动类
 * 
 * @SpringBootApplication 包含了以下注解：
 * - @Configuration：标识这是一个配置类
 * - @EnableAutoConfiguration：启用Spring Boot的自动配置机制
 * - @ComponentScan：启用组件扫描，扫描当前包及其子包下的组件
 * 
 * 暂时排除Redis、RabbitMQ和Druid的自动配置，用于演示启动
 * 
 * @author example
 * @version 1.0.0
 */
@SpringBootApplication(exclude = {
    RedisAutoConfiguration.class, 
    RabbitAutoConfiguration.class,
    com.alibaba.druid.spring.boot.autoconfigure.DruidDataSourceAutoConfigure.class
})
public class SpringMvcApplication {

    public static void main(String[] args) {
        SpringApplication.run(SpringMvcApplication.class, args);
    }

}