#!/bin/bash

source ./check_deps.sh

if [ $all_deps -eq 0 ]; then
echo ""
return
fi

# Define the port number

kill_port_forwarding() {
    # Array of ports to check and potentially kill processes for
    PORTS=(8888 4040 18080)

    for PORT in "${PORTS[@]}"; do
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
    done
}

JN_PORT="8888"

# Name of the Docker image and container
IMAGE_NAME="spark-pyspark-jupyter"
CONTAINER_NAME="spark-pyspark-jupyter"
DOCKERFILE_PATH="Dockerpyspark"
HOST_VOLUME_PATH=$(pwd)  # Host volume path


# Export variables for envsubst
export CONTAINER_NAME="spark-pyspark-jupyter"
export IMAGE_NAME="spark-pyspark-jupyter"
export HOST_VOLUME_PATH=$(pwd)  # Host volume path
NAMESPACE="pyspark-work"
export NAMESPACE=$NAMESPACE


# Path to the deploy directory
DEPLOY_DIR="$(pwd)/deploys"

# Path to the pod template
POD_TEMPLATE_DIR="$DEPLOY_DIR/templates"

# Path to the final pod definition
POD_DEFINITION_FILE="$DEPLOY_DIR/pyspark-work-spark-jn.yml"



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

    # Deploy the pods
    source $(pwd)/deploys/apply-deploys.sh
    

    # Wait for all pods in the namespace to be in the 'Running' state
    echo "Waiting for all pods in the $NAMESPACE namespace to be up..."
    while true; do
        # Get the status of all pods in the namespace
        POD_STATUSES=$(microk8s kubectl get pods -n $NAMESPACE -o=jsonpath='{.items[*].status.phase}')

        # Check if all pods are running
        ALL_RUNNING=true
        for STATUS in $POD_STATUSES; do
            if [ "$STATUS" != "Running" ]; then
                ALL_RUNNING=false
                break
            fi
        done

        if $ALL_RUNNING; then
            echo "All pods in the $NAMESPACE namespace are running."
            break
        else
            echo "Waiting for all pods in the $NAMESPACE namespace to be up..."
            sleep 5
        fi
    done

    echo "setting up port forwarding"
    # Set up port forwarding
    microk8s kubectl port-forward pod/$CONTAINER_NAME $JN_PORT:$JN_PORT -n $NAMESPACE >/dev/null 2>&1 &
    #
    microk8s kubectl port-forward pod/$CONTAINER_NAME 4040:4040 -n $NAMESPACE >/dev/null 2>&1 &
    #
    microk8s kubectl port-forward pod/$CONTAINER_NAME 18080:18080 -n $NAMESPACE >/dev/null 2>&1 &

    forward_status=$?

    echo "forward_status =$forward_status"



}

# Function to build and push a Docker image to MicroK8s registry
teardown_deploy() {
    source ./deploys/remove-deploys.sh
}


# Main script logic
mks_up=0
#get rid of the container if it's in our pods
microk8s status --format short | grep -q "microk8s is running" && mks_up=1 || mks_up=0

if [ $mks_up -eq 0 ]; then
    echo "Microk8s is not running"
    echo "run microk8s start"
    return
fi


kill_port_forwarding

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
echo "* http://127.0.0.1:$JN_PORT          *"
echo "*********************************"

finished=false
while ! $finished; do
    response_code=$(curl -o /dev/null -s -w "%{http_code}\n" -X GET "http://127.0.0.1:$JN_PORT/tree?")
    if [ "$response_code" -eq 200 ]; then
        finished=true
        echo "*********************************"
        echo "* Jupyter is ready:             *"
        echo "* http://127.0.0.1:$JN_PORT/tree?   *"
        echo "*********************************"
    else
        finished=false
    fi
done

# List pods in our namespace
microk8s kubectl get pods -n $NAMESPACE 
echo "*********************************"
echo "microk8s kubectl get pods -n $NAMESPACE "
echo "*********************************"

sleep 3
#run the spark submit job
time microk8s kubectl exec -it -n $NAMESPACE $CONTAINER_NAME bash spark-submit spark_submit.py

echo "***************************"
echo "finished"
echo "time microk8s kubectl exec -it -n $NAMESPACE $CONTAINER_NAME bash spark-submit spark_submit.py"
echo "***************************"

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

finished=false
while ! $finished; do
    response_code=$(curl -o /dev/null -s -w "%{http_code}\n" -X GET "http://127.0.0.1:18080")
    if [ "$response_code" -eq 200 ]; then
        finished=true
        echo "*********************************"
        echo "* Log Server is Live:           *"
        echo "* http://127.0.0.1:18080        *"
        echo "*********************************"
    else
        finished=false
    fi
done



while true; do
    echo "*********************************"
    echo "*                               *"
    echo "*    Do you wish to exit?       *"
    echo "* (this will shut down Pyspark in Jupyter) *"
    echo "*                               *"
    echo "*********************************"
    read -p "Do you wish to exit? [y/n]:" yn
    case $yn in
        [Yy]* ) echo "Exiting..."; teardown_deploy ; kill_port_forwarding; break;;
        [Nn]* ) echo "Continuing..."; break;;
        * ) echo "Please answer 'y' or 'n'.";;
    esac
done



sudo chmod -R 777 ./

# List pods in our namespace
microk8s kubectl get pods -n $NAMESPACE 

