#!/bin/bash

# Define the secret file
SECRET_FILE="secret.yml"

echo "*********************************"
echo "Creating the secret file containing root password for worker nodes (they all need to be the same)"
echo "*********************************"

# Check if the secret file exists
if [ ! -f "$SECRET_FILE" ]; then
    echo "Secret file not found. Let's create one."

    # Prompt for the password
    while true; do
        read -sp "Enter new secret password: " password
        echo
        read -sp "Confirm secret password: " password2
        echo

        # Check if passwords match
        if [ "$password" = "$password2" ]; then
            break
        else
            echo "Passwords do not match. Please try again."
        fi
    done

    # Create the secret file
    echo "ansible_become_pass: $password" > $SECRET_FILE
    echo "Secret file created."
else
    echo "Secret file already exists."
fi
