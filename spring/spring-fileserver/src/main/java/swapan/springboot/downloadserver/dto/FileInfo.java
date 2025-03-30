package swapan.springboot.downloadserver.dto;

public class FileInfo {

    private final String filePath;

    public FileInfo(String filePath) {
        this.filePath = filePath;
    }

    public String getFilePath() {
        return filePath;
    }

}
