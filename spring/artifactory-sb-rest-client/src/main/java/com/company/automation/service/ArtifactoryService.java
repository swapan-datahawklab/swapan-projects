package com.company.automation.service;

import com.company.automation.config.ArtifactoryProperties;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

@Service
public class ArtifactoryService {
    private final RestClient restClient;
    private final ArtifactoryProperties artifactoryProperties;

    @Autowired
    public ArtifactoryService(RestClient.Builder restClientBuilder, ArtifactoryProperties artifactoryProperties) {
        this.restClient = restClientBuilder.build();
        this.artifactoryProperties = artifactoryProperties;
    }

    public String getRepoList(String repoName) {
        String url = artifactoryProperties.getUrl() + "/api/docker/" + repoName + "/v2/_catalog";
        return restClient.get().uri(url).retrieve().body(String.class);
    }

    public String getTagList(String repoName, String tagName) {
        String url = artifactoryProperties.getUrl() + "/api/docker/" + repoName + "/v2/" + tagName + "/tags/list";
        return restClient.get().uri(url).retrieve().body(String.class);
    }
}