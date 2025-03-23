package com.company.automation.config;


import org.springframework.context.annotation.Configuration;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@Configuration
@EnableConfigurationProperties(ArtifactoryProperties.class)
public class AppConfig {

}