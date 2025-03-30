package swapan.springboot.downloadserver.rest;

import swapan.springboot.downloadserver.services.FileService;
import swapan.springboot.downloadserver.dto.FileList;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;

import java.io.IOException;
import java.nio.file.Path;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(FileServerController.class)
class FileServerControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private FileService fileService;

    @TempDir
    Path tempDir;

    @BeforeEach
    void setUp() {
    }

    @Test
    void testCreateDirectory() throws Exception {
        mockMvc.perform(post("/services/files/createdir/testdir"))
                .andExpect(status().isOk());
    }

    @Test
    void testUploadFile() throws Exception {
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "test.txt",
                "text/plain",
                "Hello, World!".getBytes()
        );

        mockMvc.perform(multipart("/services/files/upload/test.txt")
                        .file(file))
                .andExpect(status().isOk());
    }

    @Test
    void testDownloadFile() throws Exception {
        Resource resource = new ByteArrayResource("Hello, World!".getBytes());
        when(fileService.loadFileAsResource(any(Path.class))).thenReturn(resource);

        mockMvc.perform(get("/services/files/download/test.txt"))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Disposition", "attachment; filename=\"test.txt\""))
                .andExpect(content().string("Hello, World!"));
    }

    @Test
    void testListFiles() throws Exception {
        FileList fileList = new FileList("testdir");
        when(fileService.getFilesInfo(any(Path.class))).thenReturn(fileList);

        mockMvc.perform(get("/services/files/list/testdir"))
                .andExpect(status().isOk())
                .andExpect(content().contentType("application/json"));
    }

    @Test
    void testDeleteFile() throws Exception {
        mockMvc.perform(delete("/services/files/delete/test.txt"))
                .andExpect(status().isOk());
    }

    @Test
    void testDownloadFileNotFound() throws Exception {
        when(fileService.loadFileAsResource(any(Path.class)))
                .thenThrow(new IOException("File not found"));

        mockMvc.perform(get("/services/files/download/nonexistent.txt"))
                .andExpect(status().isInternalServerError());
    }
} 