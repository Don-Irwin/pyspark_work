#!/bin/bash

# Name of the Docker image
IMAGE_NAME="spark_pyspark_jupyter"

docker stop $IMAGE_NAME
docker rm $IMAGE_NAME

# Build the Docker image
docker build -t $IMAGE_NAME .

# Run the Docker container
docker run -it --rm -p 8888:8888 -v "$PWD":/workspace $IMAGE_NAME

