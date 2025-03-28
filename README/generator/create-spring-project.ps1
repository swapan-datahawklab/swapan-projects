# PowerShell Script

# Set up your project name
param (
    [string]$ProjectName
)

if (-not $ProjectName) {
    Write-Host "Usage: .\script.ps1 -ProjectName <project-name>"
    exit 1
}

# Create the base directory structure
New-Item -ItemType Directory -Path "$ProjectName/src/main/java" -Force | Out-Null
New-Item -ItemType Directory -Path "$ProjectName/src/main/resources" -Force | Out-Null
New-Item -ItemType Directory -Path "$ProjectName/src/test/java" -Force | Out-Null
New-Item -ItemType Directory -Path "$ProjectName/src/test/resources" -Force | Out-Null

# Set up standard Spring Boot directories
$baseJavaPath = "$ProjectName/src/main/java"
$baseTestPath = "$ProjectName/src/test/java"
$packagePath = "com/$ProjectName"

# Create basic packages
$folders = @("controller", "service", "repository", "config", "model", "exception")
foreach ($folder in $folders) {
    New-Item -ItemType Directory -Path "$baseJavaPath/$packagePath/$folder" -Force | Out-Null
    New-Item -ItemType Directory -Path "$baseTestPath/$packagePath/$folder" -Force | Out-Null
}

# Create README.md
$readmeContent = "# $ProjectName

A Spring Boot application."
Set-Content -Path "$ProjectName/README.md" -Value $readmeContent

# Create a basic pom.xml file
$pomContent = @"
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.$ProjectName</groupId>
    <artifactId>$ProjectName</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <packaging>jar</packaging>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-jdbc</artifactId>
        </dependency>
        <dependency>
            <groupId>org.xerial</groupId>
            <artifactId>sqlite-jdbc</artifactId>
            <version>3.36.0.3</version>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>
"@
Set-Content -Path "$ProjectName/pom.xml" -Value $pomContent

# Create .gitignore file
$gitignoreContent = @"
*.class
*.log
target/
*.jar
*.war
*.ear
.gradle
build/
.project
.classpath
.settings/
*.iml
*.ipr
*.iws
"@
Set-Content -Path "$ProjectName/.gitignore" -Value $gitignoreContent

# Create sample Java classes
$controllerContent = @"
package com.$ProjectName.controller;

import com.$ProjectName.model.User;
import com.$ProjectName.service.UserService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
    public List<User> getAllUsers() {
        return userService.getAllUsers();
    }

    @PostMapping
    public User createUser(@RequestBody User user) {
        return userService.createUser(user);
    }
}
"@
Set-Content -Path "$baseJavaPath/$packagePath/controller/UserController.java" -Value $controllerContent

$serviceContent = @"
package com.$ProjectName.service;

import com.$ProjectName.model.User;
import com.$ProjectName.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    public User createUser(User user) {
        return userRepository.save(user);
    }
}
"@
Set-Content -Path "$baseJavaPath/$packagePath/service/UserService.java" -Value $serviceContent

$repositoryContent = @"
package com.$ProjectName.repository;

import com.$ProjectName.model.User;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public class UserRepository {

    private final JdbcTemplate jdbcTemplate;

    public UserRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public List<User> findAll() {
        String sql = "SELECT * FROM users";
        return jdbcTemplate.query(sql, (rs, rowNum) -> new User(
                rs.getInt("id"),
                rs.getString("name"),
                rs.getString("email")
        ));
    }

    public User save(User user) {
        String sql = "INSERT INTO users(name, email) VALUES(?, ?)";
        jdbcTemplate.update(sql, user.getName(), user.getEmail());
        return user;
    }
}
"@
Set-Content -Path "$baseJavaPath/$packagePath/repository/UserRepository.java" -Value $repositoryContent

$configContent = @"
package com.$ProjectName.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

import javax.sql.DataSource;

@Configuration
public class DatabaseConfig {

    @Bean
    public DataSource dataSource() {
        PoolDataSource dataSource = PoolDataSourceFactory.getPoolDataSource();
        dataSource.setConnectionFactoryClassName("oracle.ucp.jdbc.PoolDataSourceImpl");
        dataSource.setURL("jdbc:sqlite:users.db");
        dataSource.setUser("");
        dataSource.setPassword("");
        dataSource.setInitialPoolSize(5);
        dataSource.setMaxPoolSize(20);
        return dataSource;
    }

    @Bean
    public JdbcTemplate jdbcTemplate(DataSource dataSource) {
        return new JdbcTemplate(dataSource);
    }
}
"@
Set-Content -Path "$baseJavaPath/$packagePath/config/DatabaseConfig.java" -Value $configContent

$modelContent = @"
package com.$ProjectName.model;

public class User {
    private int id;
    private String name;
    private String email;

    public User() {}

    public User(int id, String name, String email) {
        this.id = id;
        this.name = name;
        this.email = email;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
}
"@
Set-Content -Path "$baseJavaPath/$packagePath/model/User.java" -Value $modelContent

$exceptionContent = @"
package com.$ProjectName.exception;

public class UserNotFoundException extends RuntimeException {
    public UserNotFoundException(String message) {
        super(message);
    }
}
"@
Set-Content -Path "$baseJavaPath/$packagePath/exception/UserNotFoundException.java" -Value $exceptionContent

# Create test classes
$controllerTestContent = @"
package com.$ProjectName.controller;

import com.$ProjectName.model.User;
import com.$ProjectName.service.UserService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Collections;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;

@WebMvcTest(UserController.class)
public class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserService userService;

    @Test
    public void getAllUsers_shouldReturnOk() throws Exception {
        when(userService.getAllUsers()).thenReturn(Collections.singletonList(new User(1, "John Doe", "john.doe@example.com")));

        mockMvc.perform(get("/api/users"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].name").value("John Doe"));
    }
}
"@
Set-Content -Path "$baseTestPath/$packagePath/controller/UserControllerTest.java" -Value $controllerTestContent

$serviceTestContent = @"
package com.$ProjectName.service;

import com.$ProjectName.model.User;
import com.$ProjectName.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserService userService;

    @Test
    public void getAllUsers_shouldReturnUsers() {
        User user = new User(1, "John Doe", "john.doe@example.com");
        when(userRepository.findAll()).thenReturn(Collections.singletonList(user));

        List<User> users = userService.getAllUsers();

        assertEquals(1, users.size());
        assertEquals("John Doe", users.get(0).getName());
    }
}
"@
Set-Content -Path "$baseTestPath/$packagePath/service/UserServiceTest.java" -Value $serviceTestContent

# Print completion message
Write-Host "Spring Boot project structure for '$ProjectName' created successfully with sample classes and tests."
