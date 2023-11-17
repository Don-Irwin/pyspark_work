#!/bin/bash

docker stop ubuntu-python-codon
docker rm ubuntu-python-codon

# Create a Dockerfile
echo "Creating Dockerfile for Ubuntu slim with Python 3.10 and Codon installation..."


# Build the Docker image
echo "Building Docker image..."
docker build -f CodonDockerfile -t ubuntu-python-codon .

echo "Docker image 'ubuntu-python-codon' built successfully."

docker run -d --name ubuntu-python-codon ubuntu-python-codon
