#!/bin/bash

source ./get_secret.sh
source ./env.sh

# Uninstall PySpark
sudo pip3 uninstall -y pyspark

echo "stopping"
/spark/sbin/stop-master.sh

# Remove Spark directories
sudo rm -rf /spark
sudo rm -rf /tmp/spark-events

# Optional: Remove Spark-related environment variables from /etc/profile
sudo sed -i '/SPARK_/d' /etc/profile
ansible-playbook -i hosts uninstall_spark_playbook.yml 

sudo rm -rf $NFS_SHARE_DIR
