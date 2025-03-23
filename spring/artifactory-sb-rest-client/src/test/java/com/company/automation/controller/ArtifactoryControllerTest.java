package com.company.automation.controller;

import com.company.automation.service.ArtifactoryService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class ArtifactoryControllerTest {

    private MockMvc mockMvc;

    @Mock
    private ArtifactoryService artifactoryService;

    @InjectMocks
    private ArtifactoryController artifactoryController;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        mockMvc = MockMvcBuilders.standaloneSetup(artifactoryController).build();
    }

    @Test
    void testGetRepositories() throws Exception {
        String repoName = "example-repo";
        String repoList = "repo1, repo2, repo3";

        when(artifactoryService.getRepoList(repoName)).thenReturn(repoList);

        mockMvc.perform(get("/api/v1/artifactory/repos")
                        .param("repoName", repoName)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().string(repoList));
    }

    @Test
    void testGetTagList() throws Exception {
        String repoName = "example-repo";
        String tagName = "latest";
        String tagList = "tag1, tag2, tag3";

        when(artifactoryService.getTagList(repoName, tagName)).thenReturn(tagList);

        mockMvc.perform(get("/api/v1/artifactory/taglist")
                        .param("repoName", repoName)
                        .param("tagName", tagName)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().string(tagList));
    }
}