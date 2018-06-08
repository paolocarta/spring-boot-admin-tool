
# Makefile
# see https://www.gnu.org/software/make/manual/make.html


# VARIABLES

NAME := showcase-admin-tool
GIT_COMMIT_HASH := $(shell git log --pretty=format:'%h' -n 1)

BUILD_TOOL := ./mvnw
JAR_FILE := $(shell find build/libs -name '*.jar' 2>/dev/null)

IMAGE_NAME := samples/$(NAME)
IMAGE_TAG := latest

# CLOUD-NATIVE
IMAGE_EXPOSE_PORT := 8080
# LOCALHOST
#IMAGE_EXPOSE_PORT := 9291

DOCKER_HOST_IP := localhost
DOCKER_HOST_PORT := 5000

.PHONY: help
.DEFAULT_GOAL := help


# GENERAL

help :		## Help
	@echo ""
	@echo "*** $(NAME) Makefile help ***"
	@echo ""
	@echo "Targets list:"
	@grep -E '^[a-zA-Z_-]+ :.*?## .*$$' $(MAKEFILE_LIST) | sort -k 1,1 | awk 'BEGIN {FS = ":.*?## "}; {printf "\t\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""

print-variables :		## Print variables values
	@echo "MAKE: $(MAKE)"
	@echo "MAKEFILES: $(MAKEFILES)"
	@echo "MAKEFILE_LIST: $(MAKEFILE_LIST)"
	@echo "- - - "
	@echo "NAME: $(NAME)"
	@echo "GIT_COMMIT_HASH: $(GIT_COMMIT_HASH)"
	@echo "- - - "
	@echo "BUILD_TOOL: $(BUILD_TOOL)"
	@echo "JAR_FILE: $(JAR_FILE)"
	@echo "- - - "
	@echo "IMAGE_NAME: $(IMAGE_NAME)"
	@echo "IMAGE_TAG: $(IMAGE_TAG)"
	@echo "IMAGE_EXPOSE_PORT: $(IMAGE_EXPOSE_PORT)"
	@echo "DOCKER_HOST_IP: $(DOCKER_HOST_IP)"
	@echo "DOCKER_HOST_PORT: $(DOCKER_HOST_PORT)"


# BUILDING

build :		## Build the application excluding tests
	$(BUILD_TOOL) package -DskipTests

build-test :		## Build the application including tests
	$(BUILD_TOOL) package

clean :		## Clean the application
	$(BUILD_TOOL) clean

clean-build :		## Clean and Build the application excluding tests
	$(BUILD_TOOL) clean package -DskipTests

clean-build-test :		## Clean and Build the application including tests
	$(BUILD_TOOL) clean package


# TESTING

test : clean-build		## Run all tests in the application
	$(BUILD_TOOL) test

unit-test : clean-build		## Run Unit tests in the application
	$(BUILD_TOOL) test

integration-test : clean-build		## Run Integration tests in the application
	$(BUILD_TOOL) -Dtest=*IntegrationTest test

specific-test : clean-build		## Run Specific tests in the application
	$(BUILD_TOOL) -Dtest=$@ test


# RUNNING

run :		## Run the application through Spring Boot
	$(BUILD_TOOL) spring-boot:run -DskipTests

javarun :		## Run the application through the generated fat-jar
	java -jar $(JAR_FILE)


# DOCKER

docker-build : clean-build-test		## Build the docker IMAGE_NAME of the application
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG)-$(GIT_COMMIT_HASH) -f Dockerfile .

docker-run : docker-build		## Run the containerised application through docker
	docker run -d --name $(NAME) -p $(IMAGE_EXPOSE_PORT):$(IMAGE_EXPOSE_PORT) $(IMAGE_NAME):$(IMAGE_TAG)-$(GIT_COMMIT_HASH)

docker-stop :		## Stop the containerised application
	docker container stop -f $(NAME)

docker-push : docker-build		## Push the docker application to the docker registry
	docker push $(DOCKER_HOST_IP):$(DOCKER_HOST_PORT)/$(IMAGE_NAME):$(IMAGE_TAG)-$(GIT_COMMIT_HASH)

docker-delete-local : docker-stop		## Delete the docker IMAGE_NAME of the application
	docker container rm -f $(NAME)
	docker image rm -f $(NAME)

docker-delete-remote : docker-stop		## Delete the docker IMAGE_NAME of the application from the docker registry
	docker image remove $(DOCKER_HOST_IP):$(DOCKER_HOST_PORT)/$(IMAGE_NAME):$(IMAGE_TAG)-$(GIT_COMMIT_HASH)
