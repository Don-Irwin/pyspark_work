#!/bin/bash

# Function to get current timestamp in seconds
current_time_s() {
    date +%s
}

# Function to convert seconds to minutes and seconds
convert_to_min_sec() {
    local total_seconds=$1
    local minutes=$((total_seconds / 60))
    local seconds=$((total_seconds % 60))
    echo "${minutes}m ${seconds}s"
}

echo "*******************************"
echo "Building .net Core C# Docker Container"
echo "*******************************"
source ./csvgenerator.sh
echo "*******************************"
echo "Completed Building .net Core C# Docker Container"
echo "*******************************"

# Run the Python Data Generation process
echo "*******************************"
echo "Starting Python Data Generation process..."
echo "*******************************"
start_time_python=$(current_time_s)
# Command for the Python data generation process goes here
python gen_random_data.py
end_time_python=$(current_time_s)

# Run the C# Data Generation process
echo "*******************************"
echo "Starting C# Data Generation process..."
echo "*******************************"
start_time_csharp=$(current_time_s)
# Command for the C# data generation process goes here
docker run --name $IMAGE_NAME -v "$PWD/out":/app/publish $CONTAINER_NAME
end_time_csharp=$(current_time_s)

# Calculate the duration of each process
duration_python=$((end_time_python - start_time_python))
duration_csharp=$((end_time_csharp - start_time_csharp))

# Output the durations
echo "*******************************"
echo "Duration of Python Data Generation process: $(convert_to_min_sec $duration_python)"
echo "*******************************"
echo "Duration of C# Data Generation process: $(convert_to_min_sec $duration_csharp)"
echo "*******************************"

# Calculate and output the time delta
if [ $duration_python -gt $duration_csharp ]; then
    time_delta=$((duration_python - duration_csharp))
    echo "*******************************"
    echo "Python Data Generation process took $(convert_to_min_sec $time_delta) longer than the C# Data Generation process."
    echo "*******************************"
elif [ $duration_csharp -gt $duration_python ]; then
    time_delta=$((duration_csharp - duration_python))
    echo "*******************************"
    echo "C# Data Generation process took $(convert_to_min_sec $time_delta) longer than the Python Data Generation process."
    echo "*******************************"
else
    echo "Both processes took the same amount of time."
fi
