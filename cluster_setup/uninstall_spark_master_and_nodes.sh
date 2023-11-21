#!/bin/bash

# Uninstall PySpark
sudo pip3 uninstall -y pyspark

echo "stopping"
/spark/sbin/stop-master.sh

# Remove Spark directories
sudo rm -rf /spark
sudo rm -rf /tmp/spark-events

# Optional: Remove Spark-related environment variables from /etc/profile
sudo sed -i '/SPARK_/d' /etc/profile
ansible-playbook -i hosts uninstall_spark_playbook.yml --ask-become-pass

sudo rm $NFS_SHARE_DIR/worker*.txt
