package swapan.springboot.downloadserver.dto;

public class DirectoryInfo {

    private final String filePath;

    public DirectoryInfo(String filePath) {
        this.filePath = filePath;
    }

    public String getFilePath() {
        return filePath;
    }

}
