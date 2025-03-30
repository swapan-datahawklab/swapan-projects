package swapan.springboot.downloadserver.config;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@TestPropertySource(properties = {
    "file.server.home=/tmp/test-fileserver"
})
class FileServerConfigTest {

    @Autowired
    private FileServerConfig fileServerConfig;

    @Test
    void testGetHome() {
        assertEquals("/tmp/test-fileserver", fileServerConfig.getHome());
    }
} 