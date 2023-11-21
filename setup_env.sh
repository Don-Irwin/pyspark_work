#!/bin/bash
. get_utils.sh

# Define the file path
FILE_PATH="./out/sample_data_to_transform.csv"

# Check if the file exists
if [ ! -f "$FILE_PATH" ]; then
    echo "File not found: $FILE_PATH"
    echo "Running csvgenerator.sh..."
    . ./csvgenerator.sh
else
    echo "File already exists: $FILE_PATH"
fi
