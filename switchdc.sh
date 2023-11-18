#!/bin/bash

while true; do
    read -p "Switch Docker context to: MicroK8s (m) / Docker (d) " choice
    case "$choice" in
        m)
            if [ -S /var/snap/microk8s/current/docker.sock ]; then
                export DOCKER_HOST=unix:///var/snap/microk8s/current/docker.sock
                echo "Docker context switched to MicroK8s."
            else
                echo "MicroK8s Docker socket not found. Make sure MicroK8s is installed and the Docker addon is enabled."
            fi
            break
            ;;
        d)
            unset DOCKER_HOST
            echo "Docker context switched to the default host Docker."
            break
            ;;
        *)
            echo "Invalid input. Please enter 'm' for MicroK8s or 'd' for Docker."
            ;;
    esac
done
