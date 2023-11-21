#!/bin/bash

# Variables
IMAGE_NAME="csvgenerator"
CONTAINER_NAME="csvgenerator_container"
DOCKERFILE_PATH="CsvGeneratorDockerfile"

docker stop $IMAGE_NAME
docker rm $IMAGE_NAME

# Function to build the Docker image
build_image() {
    docker build -f $DOCKERFILE_PATH -t $CONTAINER_NAME .
}

# Build the Docker image
echo "Building the Docker image..."
build_image

if [ $? -eq 0 ]; then
    echo "Docker image $IMAGE_NAME has been built successfully."
else
    echo "*******************************"
    echo "Failed to build the Docker image."
    echo "*******************************"    
fi

echo "*******************************"
echo "Running the file generator"
time docker run --name $IMAGE_NAME -v "$PWD/out":/app/publish $CONTAINER_NAME
echo "Finished running the file generator"
echo "*******************************"

sudo chmod 777 -R ./out