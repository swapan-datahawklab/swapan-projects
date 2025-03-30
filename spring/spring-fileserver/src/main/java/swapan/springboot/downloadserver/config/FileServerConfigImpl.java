package swapan.springboot.downloadserver.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties("file.server")
public class FileServerConfigImpl implements FileServerConfig {
    private String home;

    @Override
    public String getHome() {
        return home;
    }

    @Override
    public void setHome(String home) {
        this.home = home;
    }
} 