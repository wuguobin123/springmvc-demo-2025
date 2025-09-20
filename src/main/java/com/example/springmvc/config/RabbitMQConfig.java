package com.example.springmvc.config;

import org.springframework.amqp.core.*;
import org.springframework.amqp.rabbit.config.SimpleRabbitListenerContainerFactory;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * RabbitMQ配置类
 * 
 * 配置消息队列相关设置：
 * - RabbitTemplate配置
 * - 消息转换器配置
 * - 队列、交换机、绑定关系配置
 * - 监听器容器配置等
 * 
 * @author example
 * @version 1.0.0
 */
@Configuration
@ConditionalOnProperty(name = "spring.rabbitmq.host")
public class RabbitMQConfig {

    // 示例队列名称
    public static final String DEMO_QUEUE = "demo.queue";
    public static final String DEMO_EXCHANGE = "demo.exchange";
    public static final String DEMO_ROUTING_KEY = "demo.routing.key";

    /**
     * 配置消息转换器
     */
    @Bean
    public MessageConverter messageConverter() {
        return new Jackson2JsonMessageConverter();
    }

    /**
     * 配置RabbitTemplate
     */
    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
        RabbitTemplate rabbitTemplate = new RabbitTemplate(connectionFactory);
        rabbitTemplate.setMessageConverter(messageConverter());
        
        // 设置消息确认机制
        rabbitTemplate.setConfirmCallback((correlationData, ack, cause) -> {
            if (ack) {
                System.out.println("消息发送成功: " + correlationData);
            } else {
                System.out.println("消息发送失败: " + correlationData + ", 原因: " + cause);
            }
        });
        
        rabbitTemplate.setReturnsCallback(returned -> {
            System.out.println("消息被退回: " + returned.getMessage());
        });
        
        return rabbitTemplate;
    }

    /**
     * 配置监听器容器工厂
     */
    @Bean
    public SimpleRabbitListenerContainerFactory rabbitListenerContainerFactory(ConnectionFactory connectionFactory) {
        SimpleRabbitListenerContainerFactory factory = new SimpleRabbitListenerContainerFactory();
        factory.setConnectionFactory(connectionFactory);
        factory.setMessageConverter(messageConverter());
        return factory;
    }

    /**
     * 声明示例队列
     */
    @Bean
    public Queue demoQueue() {
        return QueueBuilder.durable(DEMO_QUEUE).build();
    }

    /**
     * 声明示例交换机
     */
    @Bean
    public DirectExchange demoExchange() {
        return new DirectExchange(DEMO_EXCHANGE);
    }

    /**
     * 绑定队列和交换机
     */
    @Bean
    public Binding demoBinding() {
        return BindingBuilder.bind(demoQueue()).to(demoExchange()).with(DEMO_ROUTING_KEY);
    }

    // TODO: 根据业务需求添加更多队列、交换机和绑定关系

}