package com.example.bitbucketscraper.config;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SeleniumConfig {
    @Bean
    public WebDriver webDriver() {
        System.setProperty("webdriver.chrome.driver", "path/to/chromedriver");
        return new ChromeDriver();
    }
}

// BitbucketCommands.java
package com.example.bitbucketscraper.commands;

import com.example.bitbucketscraper.services.BitbucketService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.shell.standard.ShellComponent;
import org.springframework.shell.standard.ShellMethod;
import org.springframework.shell.standard.ShellOption;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

@ShellComponent
public class BitbucketCommands {

    private static final Logger logger = LoggerFactory.getLogger(BitbucketCommands.class);

    private final BitbucketService bitbucketService;

    @Autowired
    public BitbucketCommands(BitbucketService bitbucketService) {
        this.bitbucketService = bitbucketService;
    }

    @ShellMethod("Scrape multiple Bitbucket repositories by providing their URLs with pagination support.")
    public void scrapeRepos(@ShellOption List<String> repoUrls, @ShellOption(defaultValue = "1") int page, @ShellOption(defaultValue = "5") int pageSize) {
        try {
            logger.info("Starting to scrape repositories: {}", repoUrls);
            bitbucketService.scrapeRepositories(repoUrls, page, pageSize);
            logger.info("Finished scraping repositories.");
        } catch (Exception e) {
            logger.error("An error occurred while scraping repositories: {}", e.getMessage(), e);
        }
    }
}

// BitbucketService.java
package com.example.bitbucketscraper.services;

import com.example.bitbucketscraper.repositories.BitbucketRepository;
import com.example.bitbucketscraper.reports.HtmlReportGenerator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

@Service
public class BitbucketService {

    private static final Logger logger = LoggerFactory.getLogger(BitbucketService.class);

    private final BitbucketRepository bitbucketRepository;
    private final HtmlReportGenerator htmlReportGenerator;

    @Autowired
    public BitbucketService(BitbucketRepository bitbucketRepository, HtmlReportGenerator htmlReportGenerator) {
        this.bitbucketRepository = bitbucketRepository;
        this.htmlReportGenerator = htmlReportGenerator;
    }

    public void scrapeRepositories(List<String> repoUrls, int page, int pageSize) {
        int start = (page - 1) * pageSize;
        int end = Math.min(start + pageSize, repoUrls.size());

        if (start >= repoUrls.size()) {
            logger.warn("No more repositories to scrape.");
            System.out.println("No more repositories to scrape.");
            return;
        }

        List<String> paginatedRepoUrls = repoUrls.subList(start, end);
        paginatedRepoUrls.forEach(repoUrl -> {
            try {
                logger.info("Scraping repository: {}", repoUrl);
                String repositoryData = bitbucketRepository.getLatestBranches(repoUrl);
                logger.info("Successfully scraped repository: {}", repoUrl);
                System.out.println("Repository Data: " + repositoryData);
                htmlReportGenerator.generateReport(repoUrl, repositoryData);
            } catch (Exception e) {
                logger.error("Failed to scrape repository {}: {}", repoUrl, e.getMessage(), e);
                System.err.println("Failed to scrape repository " + repoUrl + ": " + e.getMessage());
            }
        });
    }
}

// BitbucketRepository.java
package com.example.bitbucketscraper.repositories;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebDriverException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.stream.Collectors;

@Repository
public class BitbucketRepository {

    private static final Logger logger = LoggerFactory.getLogger(BitbucketRepository.class);

    private final WebDriver webDriver;

    @Autowired
    public BitbucketRepository(WebDriver webDriver) {
        this.webDriver = webDriver;
    }

    public String getLatestBranches(String repoUrl) {
        try {
            logger.info("Navigating to repository branches page: {}", repoUrl);
            webDriver.get(repoUrl + "/branches");

            String pageSource = webDriver.getPageSource();

            Document document = Jsoup.parse(pageSource);
            List<Element> branchElements = document.select("div[data-qa='branch-row']");

            List<String> branches = branchElements.stream()
                    .filter(element -> element.text().contains("feature/") || element.text().contains("release/"))
                    .limit(4)
                    .map(element -> {
                        String branchName = element.select("a[data-qa='branch-name']").text();
                        String lastModified = element.select("time").attr("datetime");
                        return String.format("Branch: %s, Last Modified: %s", branchName, lastModified);
                    })
                    .collect(Collectors.toList());

            logger.info("Successfully extracted branch information for repository: {}", repoUrl);
            return String.join("\n", branches);
        } catch (WebDriverException e) {
            logger.error("Error accessing the repository page {}: {}", repoUrl, e.getMessage(), e);
            throw new RuntimeException("Error accessing the repository page: " + e.getMessage(), e);
        } catch (Exception e) {
            logger.error("Error parsing repository data for {}: {}", repoUrl, e.getMessage(), e);
            throw new RuntimeException("Error parsing repository data: " + e.getMessage(), e);
        }
    }
}

// HtmlReportGenerator.java
package com.example.bitbucketscraper.reports;

import org.springframework.stereotype.Component;
import gg.jte.TemplateEngine;
import gg.jte.output.FileOutput;
import java.io.File;
import java.io.IOException;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;

@Component
public class HtmlReportGenerator {
    private final TemplateEngine templateEngine;

    public HtmlReportGenerator() {
        templateEngine = TemplateEngine.createPrecompiled(Path.of("jte-classes"));
    }

    public void generateReport(String repoUrl, String repositoryData) {
        Map<String, Object> params = new HashMap<>();
        params.put("repoUrl", repoUrl);
        params.put("repositoryData", repositoryData);

        try {
            templateEngine.render("report.jte", params, FileOutput.of(new File("report_" + repoUrl.hashCode() + ".html")));
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}

// BitbucketScraperApplication.java
package com.example.bitbucketscraper;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.shell.command.annotation.CommandScan;

@SpringBootApplication
@CommandScan("com.example.bitbucketscraper.commands")
public class BitbucketScraperApplication {

    public static void main(String[] args) {
        SpringApplication.run(BitbucketScraperApplication.class, args);
    }
}

// BitbucketRepositoryData.java
package com.example.bitbucketscraper.models;

public class BitbucketRepositoryData {
    private String name;
    private String owner;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getOwner() {
        return owner;
    }

    public void setOwner(String owner) {
        this.owner = owner;
    }
}

// BitbucketServiceTest.java
package com.example.bitbucketscraper.services;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class BitbucketServiceTest {
    @Test
    public void testServiceFunctionality() {
        // TODO: Add test logic here
    }
}

// BitbucketRepositoryTest.java
package com.example.bitbucketscraper.repositories;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class BitbucketRepositoryTest {
    @Test
    public void testRepositoryFunctionality() {
        // TODO: Add test logic here
    }
}




To run a Makefile directly from VSCode on Windows using Git Bash, follow these steps:

### Step 1: Install Make and Git Bash
- Make sure you have Git for Windows installed, which comes with Git Bash.
- Install Make, as it is not included with Git Bash by default. You can install it by:
  1. Downloading a Windows-compatible Make executable (e.g., from Ezwinports) and adding it to your system's PATH.
  2. Alternatively, you can install it using a package manager like [Chocolatey](https://chocolatey.org/) or [Scoop](https://scoop.sh/).

### Step 2: Set Git Bash as the Default Terminal in VSCode
1. Open VSCode.
2. Go to the command palette (`Ctrl+Shift+P`).
3. Search for and select "Terminal: Select Default Profile".
4. Choose "Git Bash" from the list.

### Step 3: Create a Task to Run the Makefile
You can set up a custom task in VSCode to run your Makefile. Here's how:

1. Press `Ctrl+Shift+P` and select `Tasks: Configure Task`.
2. If prompted, select `Create tasks.json file from template`, then choose `Others`.
3. Add a new task configuration for running `make`:

   ```json
   {
       "version": "2.0.0",
       "tasks": [
           {
               "label": "Run Makefile",
               "type": "shell",
               "command": "make",
               "args": [],
               "problemMatcher": [],
               "group": {
                   "kind": "build",
                   "isDefault": true
               },
               "options": {
                   "shell": {
                       "executable": "C:\\Program Files\\Git\\bin\\bash.exe"
                   }
               },
               "presentation": {
                   "reveal": "always",
                   "panel": "shared"
               }
           }
       ]
   }
   ```

   Make sure to replace the `"executable"` path with the actual path to your Git Bash executable if it's different.

### Step 4: Run the Task
1. Open the terminal in VSCode (`Ctrl+\``).
2. Press `Ctrl+Shift+B` to run the "Run Makefile" task, or you can go to `Terminal > Run Build Task` and choose your task.

This setup will run `make` in Git Bash, allowing you to use a Makefile directly from VSCode on Windows.