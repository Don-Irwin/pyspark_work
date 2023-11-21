#!/bin/bash

# NFS Configuration Variables
NFS_SERVER_IP="192.168.50.235"
NFS_SHARE_DIR="/sparkcluster/fileshare"
export NFS_SHARE_DIR=$NFS_SHARE_DIR
NETWORK_RANGE="192.168.50.0/24"
MOUNT_POINT="/sparkcluster/fileshare"

