package com.example.springmvc.config;

import com.alibaba.druid.pool.DruidDataSource;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.transaction.annotation.EnableTransactionManagement;

import javax.sql.DataSource;

/**
 * 数据源配置类
 * 
 * 配置数据库连接相关设置：
 * - Druid连接池配置
 * - 事务管理配置
 * - 多数据源配置（可扩展）
 * 
 * @author example
 * @version 1.0.0
 */
@Configuration
@EnableTransactionManagement
public class DataSourceConfig {

    /**
     * 配置主数据源
     * 使用Druid连接池
     */
    @Bean
    @Primary
    @ConfigurationProperties(prefix = "spring.datasource")
    public DataSource dataSource() {
        DruidDataSource dataSource = new DruidDataSource();
        return dataSource;
    }

    // TODO: 如果需要多数据源，可以在这里配置其他数据源
    // @Bean
    // @ConfigurationProperties(prefix = "spring.datasource.secondary")
    // public DataSource secondaryDataSource() {
    //     return new DruidDataSource();
    // }

}