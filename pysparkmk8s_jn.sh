#!/bin/bash

# Define the port number
PORT="8888"

# Find the PID of the process using the specified port
PID=$(sudo lsof -t -i:$PORT)

# Check if a PID was found
if [ ! -z "$PID" ]; then
    echo "Process found on port $PORT with PID: $PID. Attempting to kill..."
    sudo kill $PID

    # Optional: Check if the process was successfully killed
    if kill -0 $PID 2>/dev/null; then
        echo "Failed to kill process $PID. It might require stronger measures."
    else
        echo "Process $PID successfully killed."
    fi
else
    echo "No process found running on port $PORT."
fi

# Name of the Docker image and container
IMAGE_NAME="spark-pyspark-jupyter"
CONTAINER_NAME="spark-pyspark-jupyter"
DOCKERFILE_PATH="Dockerpyspark"
HOST_VOLUME_PATH=$(pwd)  # Host volume path

#get rid of the container if it's in our pods
microk8s kubectl delete pod $CONTAINER_NAME

# Export variables for envsubst
export CONTAINER_NAME="spark-pyspark-jupyter"
export IMAGE_NAME="spark-pyspark-jupyter"
export HOST_VOLUME_PATH=$(pwd)  # Host volume path

# Create Pod Template
POD_TEMPLATE='apiVersion: v1
kind: Pod
metadata:
  name: $CONTAINER_NAME
spec:
  containers:
  - name: $CONTAINER_NAME
    image: localhost:32000/$IMAGE_NAME
    ports:
    - containerPort: 8888
    volumeMounts:
    - name: host-volume
      mountPath: /workspace
  volumes:
  - name: host-volume
    hostPath:
      path: $HOST_VOLUME_PATH
      type: Directory'


# Function to check if a Docker image exists in MicroK8s registry
check_image_exists() {
    docker image inspect localhost:32000/$IMAGE_NAME > /dev/null 2>&1
}

# Function to remove a Docker image from MicroK8s registry
remove_image() {
    docker rmi -f localhost:32000/$IMAGE_NAME
}

# Function to build and push a Docker image to MicroK8s registry
build_image() {
    docker build -f $DOCKERFILE_PATH -t localhost:32000/$IMAGE_NAME .
    docker push localhost:32000/$IMAGE_NAME
}

# Function to deploy to MicroK8s and set up port forwarding
deploy_to_microk8s() {
    # Substitute environment variables and create a pod definition
    echo "$POD_TEMPLATE" | envsubst > pod-definition.yml
    #cat pod-definition.yml  # Add this line for debugging


    # Deploy the pod
    microk8s kubectl apply -f pod-definition.yml

    # Wait for the pod to be in the 'Running' state
    echo "Waiting for pod $CONTAINER_NAME to be up..."
    while true; do
        POD_STATUS=$(microk8s kubectl get pod $CONTAINER_NAME -o=jsonpath='{.status.phase}')
        if [ "$POD_STATUS" == "Running" ]; then
            echo "Pod $CONTAINER_NAME is running."
            break
        else
            echo "Waiting for pod $CONTAINER_NAME to be up... Current status: $POD_STATUS"
            sleep 5
        fi
    done

    # Set up port forwarding
    microk8s kubectl port-forward pod/$CONTAINER_NAME 8888:8888 >/dev/null 2>&1 &
}

# Main script logic
if check_image_exists; then
    while true; do
        echo "*********************************"
        read -p "* Image $IMAGE_NAME exists in MicroK8s registry. Remove and rebuild? (y/n) " answer
        echo "*********************************"
        case $answer in
            [Yy]* ) remove_image; build_image; echo "Image $IMAGE_NAME has been rebuilt."; break;;
            [Nn]* ) echo "Using existing image to run in MicroK8s."; break;;
            * ) echo "Please answer 'y' or 'n'.";;
        esac
    done
    deploy_to_microk8s
    echo "Container with image $IMAGE_NAME is running in MicroK8s."
else
    echo "Image $IMAGE_NAME does not exist in MicroK8s registry. Building image..."
    build_image
    echo "Image $IMAGE_NAME has been built."
    deploy_to_microk8s
    echo "Container with image $IMAGE_NAME is running in MicroK8s."
fi

echo ""
echo "*********************************"
echo "* Waiting for Jupyter to come up:"
echo "* http://127.0.0.1:8888          *"
echo "*********************************"

finished=false
while ! $finished; do
    response_code=$(curl -o /dev/null -s -w "%{http_code}\n" -X GET "http://127.0.0.1:8888/tree?")
    if [ "$response_code" -eq 200 ]; then
        finished=true
        echo "*********************************"
        echo "* Jupyter is ready:             *"
        echo "* http://127.0.0.1:8888/tree?   *"
        echo "*********************************"
    else
        finished=false
    fi
done

# List pods containing container name
microk8s kubectl get pods | grep $CONTAINER_NAME

while true; do
    echo "*********************************"
    echo "*                               *"
    echo "*    Do you wish to exit?       *"
    echo "* (this will shut down Jupyter) *"
    echo "*                               *"
    echo "*********************************"
    read -p "Do you wish to exit? [y/n]:" yn
    case $yn in
        [Yy]* ) echo "Exiting..."; microk8s kubectl delete pod $CONTAINER_NAME; break;;
        [Nn]* ) echo "Continuing..."; break;;
        * ) echo "Please answer 'y' or 'n'.";;
    esac
done

sudo chmod -R 777 ./

# List pods containing container name
microk8s kubectl get pods | grep $CONTAINER_NAME
