package com.company.automation.dto;

import jakarta.validation.constraints.NotBlank;

public class RepoRequest {

    @NotBlank(message = "Repository name is mandatory")
    private String repoName;

    public String getRepoName() {
        return repoName;
    }

    public void setRepoName(String repoName) {
        this.repoName = repoName;
    }
}
