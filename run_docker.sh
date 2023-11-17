#!/bin/bash

# Name of the Docker image
IMAGE_NAME="spark_pyspark_jupyter"
DOCKERFILE="Dockerfile"

docker stop $IMAGE_NAME
#docker rm $IMAGE_NAME

# Build the Docker image
docker build -t $IMAGE_NAME .

# Run the Docker container
docker run -p 8888:8888 -v "$PWD":/workspace -d --name ${IMAGE_NAME} $IMAGE_NAME 


while ${prompt_for_exit}; do
        echo "*********************************"
        echo "*                               *"
        echo "*    Do you wish to exit        *"
        echo "*                               *"        
        echo " (this will shut down the system)"
        echo "*                               *"
        echo "*********************************"
        while true; do
            read -p "Do wish to kill exit? [y/n]:" yn
            case $yn in
                [Yy]* ) do_exit=1;break;;
                [Nn]* ) do_exit=0;break;;
                * ) echo "Please answer \"y\" or \"n\".";;
            esac
        done        
break
 
done

if [[ "$do_exit" -eq 1 ]]
then
echo "*********************************"
echo "*                               *"
echo "*        exiting                *"
echo "*                               *"
echo "*********************************"

docker stop $IMAGE_NAME

export do_exit=$do_exit
fi
