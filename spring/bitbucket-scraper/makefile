# Makefile to create the project directories and touch artifact files

export PROJECT_ROOT=src/main/java/com/example/bitbucketscraper &&\
export TEST_ROOT="src/test/java/com/example/bitbucketscraper"

# Create project directories
mkdir -p ${PROJECT_ROOT}/config
mkdir -p ${PROJECT_ROOT}/commands
mkdir -p ${PROJECT_ROOT}/services
mkdir -p ${PROJECT_ROOT}/repositories
mkdir -p ${PROJECT_ROOT}/models
mkdir -p ${PROJECT_ROOT}/reports
mkdir -p ${TEST_ROOT}/services
mkdir -p ${TEST_ROOT}/repositories

# Touch artifact files
touch ${PROJECT_ROOT}/config/SeleniumConfig.java &&\
touch ${PROJECT_ROOT}/commands/BitbucketCommands.java &&\
touch ${PROJECT_ROOT}/services/BitbucketService.java &&\
touch ${PROJECT_ROOT}/repositories/BitbucketRepository.java &&\
touch ${PROJECT_ROOT}/reports/HtmlReportGenerator.java &&\
touch ${PROJECT_ROOT}/models/BitbucketRepositoryData.java &&\
touch ${PROJECT_ROOT}/BitbucketScraperApplication.java &&\
touch ${TEST_ROOT}/services/BitbucketServiceTest.java &&\
touch ${TEST_ROOT}/repositories/BitbucketRepositoryTest.java

echo "Project structure and artifact files have been created successfully."

# clean:
# 	# Remove all generated directories and files
# 	@rm -rf src
# 	@echo "Project structure has been cleaned up."