#!/bin/bash

#mvn clean install
#mvn spring-boot:run
#./file_operations.sh

# Create a test file in /tmp using here document
cat > /tmp/file.txt << 'EOF'
This is a test file created using a here document.
It contains multiple lines of text.
The file will be used for testing file operations.
EOF

# Create a directory
echo "Creating directory..."
curl -X POST "http://localhost:8888/services/files/createdir/path/to"

# List contents of directory
echo "Listing directory contents..."
curl -X GET "http://localhost:8888/services/files/list/path/to"

# Upload the test file
echo "Uploading file..."
curl -F "file=@/tmp/file.txt" "http://localhost:8888/services/files/upload/path/to/file.txt"

# List contents again to verify upload
echo "Listing directory contents after upload..."
curl -X GET "http://localhost:8888/services/files/list/path/to"

# Download the file
echo "Downloading file..."
curl -X GET "http://localhost:8888/services/files/download/path/to/file.txt" -o downloaded-file.txt

# Delete the file
echo "Deleting file..."
curl -X DELETE "http://localhost:8888/services/files/delete/path/to/file.txt"

# List contents one final time to verify deletion
echo "Listing directory contents after deletion..."
curl -X GET "http://localhost:8888/services/files/list/path/to"

# Clean up the temporary file
rm /tmp/file.txt 