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
}1`