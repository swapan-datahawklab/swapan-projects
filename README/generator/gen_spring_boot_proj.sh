#!/bin/bash

# Base directory for the project
BASE_DIR="src/main/java/com/company/automation"

# Create directories
mkdir -p $BASE_DIR/config
mkdir -p $BASE_DIR/dto
mkdir -p $BASE_DIR/service
mkdir -p $BASE_DIR/controller
mkdir -p $BASE_DIR/advice

# Create RestClientConfig.java
cat > $BASE_DIR/config/RestClientConfig.java <<EOL
package com.company.automation.config;

import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

@Configuration
public class RestClientConfig {

    @Bean
    public RestTemplate restTemplate(RestTemplateBuilder builder) {
        return builder.build();
    }
}
EOL

# Create RepoRequest.java
cat > $BASE_DIR/dto/RepoRequest.java <<EOL
package com.company.automation.dto;

import jakarta.validation.constraints.NotBlank;

public class RepoRequest {

    @NotBlank(message = "Repository name is mandatory")
    private String repoName;

    // getters and setters
}
EOL

# Create ArtifactoryService.java
cat > $BASE_DIR/service/ArtifactoryService.java <<EOL
package com.company.automation.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class ArtifactoryService {

    private final RestTemplate restTemplate;

    @Autowired
    public ArtifactoryService(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    public String getRepoList(String repoName) {
        String url = "http://localhost:8081/artifactory/api/docker/" + repoName + "/v2/_catalog";
        return restTemplate.getForObject(url, String.class);
    }
}
EOL

# Create ArtifactoryController.java
cat > $BASE_DIR/controller/ArtifactoryController.java <<EOL
package com.company.automation.controller;

import com.company.automation.dto.RepoRequest;
import com.company.automation.service.ArtifactoryService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/artifactory")
public class ArtifactoryController {

    private final ArtifactoryService artifactoryService;

    @Autowired
    public ArtifactoryController(ArtifactoryService artifactoryService) {
        this.artifactoryService = artifactoryService;
    }

    @GetMapping("/repos")
    public ResponseEntity<String> getRepositories(@Valid @RequestBody RepoRequest repoRequest) {
        String repoList = artifactoryService.getRepoList(repoRequest.getRepoName());
        return ResponseEntity.ok(repoList);
    }
}
EOL

# Create GlobalExceptionHandler.java
cat > $BASE_DIR/advice/GlobalExceptionHandler.java <<EOL
package com.company.automation.advice;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.MethodArgumentNotValidException;

import java.util.HashMap;
import java.util.Map;

@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ResponseEntity<Map<String, String>> handleValidationExceptions(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(error ->
                errors.put(error.getField(), error.getDefaultMessage()));
        return ResponseEntity.badRequest().body(errors);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<String> handleGenericException(Exception ex) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ex.getMessage());
    }
}
EOL

# Create application.properties
mkdir -p src/main/resources
cat > src/main/resources/application.properties <<EOL
local-docker-repo.url=http://localhost:8081/artifactory
EOL