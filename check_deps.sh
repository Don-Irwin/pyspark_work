#!/bin/bash

# Path to the file containing the commands
DEPS_FILE="$(pwd)/linux_dependencies.txt"

# Flag to track if all dependencies are installed
all_deps=1

# Read and execute each command from the file
while IFS= read -r line; do
    # Extract the command (first word) from the line
    cmd=$(echo $line | awk '{print $1}')

    echo "*********************************"
    echo "Checking if \"$cmd\" is installed..."
    $line >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "\"$cmd\" is installed."
    else
        echo "*********************************"
        echo "\"$cmd\" is not installed."
        all_deps=0
    fi
    echo "*********************************"
done < "$DEPS_FILE"

# Check if any dependency was not installed
if [ $all_deps -eq 0 ]; then
    echo "*********************************"
    echo "Not all dependencies are installed. Please review the output above."
    echo "*********************************"
else
    echo "*********************************"
    echo "All dependencies are installed. Continuing."
    echo "*********************************"
fi

export all_deps=$all_deps
