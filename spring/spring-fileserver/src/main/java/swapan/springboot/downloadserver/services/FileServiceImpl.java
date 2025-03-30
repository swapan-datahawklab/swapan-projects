package swapan.springboot.downloadserver.services;

import swapan.springboot.downloadserver.dto.FileList;
import swapan.springboot.downloadserver.dto.DirectoryInfo;
import swapan.springboot.downloadserver.dto.FileInfo;
import swapan.springboot.downloadserver.config.FileServerConfig;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.util.FileSystemUtils;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.stream.Stream;

@Service
public class FileServiceImpl implements FileService {

    private static final Logger LOG = LoggerFactory.getLogger(FileServiceImpl.class);

    private final Path fileStorageLocation;

    @Autowired
    public FileServiceImpl(FileServerConfig fileServerConfig) {
        LOG.info("fileStorageLocation={}", fileServerConfig.getHome());
        fileStorageLocation = Paths.get(fileServerConfig.getHome())
                .toAbsolutePath().normalize();
    }

    @Override
    public Path getBasePath() {
        return fileStorageLocation;
    }

    @Override
    public Resource loadFileAsResource(Path filePath) throws IOException {
        LOG.info("loadFileAsResource: {}", filePath);
        try {
            Path resolvedFilePath = this.fileStorageLocation.resolve(filePath).normalize();
            Resource resource = new UrlResource(resolvedFilePath.toUri());
            if(resource.exists()) {
                return resource;
            } else {
                throw new IOException("File not found " + filePath);
            }
        } catch (MalformedURLException ex) {
            throw new IOException("File not found " + filePath, ex);
        }
    }

    @Override
    public FileList getFilesInfo(Path filePath) throws IOException {
        LOG.info("getFilesInfo: {}", filePath);
        FileList fileList = new FileList(filePath.toString());
        Path resolvedFilePath = this.fileStorageLocation.resolve(filePath).normalize();
        try (Stream<Path> filesWalk = Files.walk(resolvedFilePath, 1)) {
            filesWalk.forEach(fw -> {
                if (resolvedFilePath.endsWith(fw)) {
                    //skip parent directory
                } else if (Files.isDirectory(fw)) {
                    fileList.add(new DirectoryInfo(fw.getFileName().toString()));
                } else {
                    fileList.add(new FileInfo(fw.getFileName().toString()));
                }
            });
        }
        return fileList;
    }

    @Override
    public void saveFile(Path filePath, InputStream inputStream) throws IOException {
        LOG.info("saveFile: {}", filePath);
        Path resolvedFilePath = this.fileStorageLocation.resolve(filePath).normalize();
        byte[] buffer = new byte[inputStream.available()];
        inputStream.read(buffer);
        File targetFile = resolvedFilePath.toFile();
        try (OutputStream outStream = new FileOutputStream(targetFile)) {
            outStream.write(buffer);
        }
    }

    @Override
    public void delete(Path filePath) throws IOException {
        LOG.info("delete: {}", filePath);
        Path resolvedFilePath = this.fileStorageLocation.resolve(filePath).normalize();
        LOG.info("deleting: {}", resolvedFilePath.toString());
        if (Files.isDirectory(resolvedFilePath)) {
            FileSystemUtils.deleteRecursively(resolvedFilePath);
        } else {
            Files.delete(resolvedFilePath);
        }
    }

    @Override
    public void createDirectory(Path filePath) throws IOException {
        LOG.info("createDirectory: {}", filePath);
        Path resolvedFilePath = this.fileStorageLocation.resolve(filePath).normalize();
        Files.createDirectories(resolvedFilePath);
    }

}
