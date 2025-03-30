package swapan.springboot.downloadserver.services;

import swapan.springboot.downloadserver.config.FileServerConfig;
import swapan.springboot.downloadserver.dto.FileList;
import swapan.springboot.downloadserver.services.FileServiceImpl;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.core.io.Resource;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import static org.junit.jupiter.api.Assertions.*;

class FileServiceTest {

    @TempDir
    Path tempDir;

    private FileServiceImpl fileService;
    private Path testFile;
    private Path testDir;

    @BeforeEach
    void setUp() {
        fileService = new FileServiceImpl(new TestFileServerConfig(tempDir.toString()));
        testFile = Paths.get("test.txt");
        testDir = Paths.get("testdir");
    }

    @Test
    void testCreateDirectory() throws IOException {
        fileService.createDirectory(testDir);
        assertTrue(Files.exists(tempDir.resolve(testDir)));
    }

    @Test
    void testSaveAndLoadFile() throws IOException {
        // Create test content
        String content = "Hello, World!";
        MultipartFile multipartFile = new MockMultipartFile(
            "file",
            "test.txt",
            "text/plain",
            content.getBytes()
        );

        // Save file
        fileService.saveFile(testFile, multipartFile.getInputStream());

        // Load and verify file
        Resource resource = fileService.loadFileAsResource(testFile);
        assertNotNull(resource);
        assertTrue(resource.exists());
    }

    @Test
    void testGetFilesInfo() throws IOException {
        // Create test directory and file
        fileService.createDirectory(testDir);
        String content = "Test content";
        MultipartFile multipartFile = new MockMultipartFile(
            "file",
            "test.txt",
            "text/plain",
            content.getBytes()
        );
        fileService.saveFile(testDir.resolve("test.txt"), multipartFile.getInputStream());

        // Get directory info
        FileList fileList = fileService.getFilesInfo(testDir);
        assertNotNull(fileList);
        assertEquals(1, fileList.getFileInfo().size());
        assertEquals("test.txt", fileList.getFileInfo().get(0).getFilePath());
    }

    @Test
    void testDelete() throws IOException {
        // Create and save test file
        String content = "Test content";
        MultipartFile multipartFile = new MockMultipartFile(
            "file",
            "test.txt",
            "text/plain",
            content.getBytes()
        );
        fileService.saveFile(testFile, multipartFile.getInputStream());

        // Delete file
        fileService.delete(testFile);

        // Verify file is deleted
        assertFalse(Files.exists(tempDir.resolve(testFile)));
    }

    private static class TestFileServerConfig implements FileServerConfig {
        private final String home;

        public TestFileServerConfig(String home) {
            this.home = home;
        }

        @Override
        public String getHome() {
            return home;
        }

        @Override
        public void setHome(String home) {
            throw new UnsupportedOperationException("Not needed for tests");
        }
    }
} 