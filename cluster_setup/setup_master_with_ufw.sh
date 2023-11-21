#!/bin/bash
source ./get_secret.sh
source ./env.sh
echo "*******************************"
echo "Setup an NFS Share"
echo "*******************************"

# Check and install NFS Server if not installed
if ! dpkg -s nfs-kernel-server >/dev/null 2>&1; then
    sudo apt update
    sudo apt install nfs-kernel-server -y
fi

# NFS Configuration Variables
NFS_SERVER_IP="192.168.50.235"
NFS_SHARE_DIR="/sparkcluster/fileshare"
export NFS_SHARE_DIR=$NFS_SHARE_DIR
NETWORK_RANGE="192.168.50.0/24"
MOUNT_POINT="/sparkcluster/fileshare"

# Create and configure NFS share directory
sudo mkdir -p "$NFS_SHARE_DIR"
sudo chown nobody:nogroup "$NFS_SHARE_DIR"
sudo chmod 777 "$NFS_SHARE_DIR"  # Setting full permissions for the directory

# Setup NFS exports
echo "$NFS_SHARE_DIR $NETWORK_RANGE(rw,sync,no_root_squash,no_subtree_check)" | sudo tee /etc/exports

# Reload the NFS exports and restart NFS server
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server

# Remove droppings of files in place
sudo rm $NFS_SHARE_DIR/worker*.txt


echo "stopping"
echo "/spark/sbin/stop-master.sh"
/spark/sbin/stop-master.sh


# Array of ports to check and potentially kill processes for
PORTS=(7077)

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

echo "*************************************"
echo "copy requirements from root"
echo "*************************************"

cp ./../pyspark_requirements.txt ./

# Check if Ansible is installed and install if it's not
echo "*************************************"
echo "Checking and installing Ansible if needed"
echo "*************************************"
if ! command -v ansible > /dev/null 2>&1; then
    echo "Installing Ansible..."
    sudo apt update
    sudo apt install ansible -y
fi

# Check if UFW is installed and install and configure if it's not
echo "*************************************"
echo "Checking and installing UFW if needed"
echo "*************************************"
if ! command -v ufw > /dev/null 2>&1; then
    echo "Installing UFW..."
    sudo apt install ufw -y
    sudo ufw allow 7077
    sudo ufw enable
fi

echo "*************************************"
echo "configuring ssh connection with the slaves"
echo "*************************************"

# Generate SSH key (if not already generated)
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
fi

echo "*************************************"
echo "Completed this section."
echo "*************************************"

# Define the path to the Ansible hosts file
HOSTS_FILE="hosts"  # Specify the file name

# Worker count for naming ssh scripts
WORKER_COUNT=1

# Extract IPs and usernames of workers from the hosts file
echo "*************************************"
echo "Processing worker nodes from $HOSTS_FILE and creating SSH scripts"
echo "*************************************"
while IFS= read -r line; do
    if [[ $line == \[workers\]* ]]; then
        read_worker_info=true
    elif [[ $line == \[* ]]; then
        read_worker_info=false
    elif [[ $read_worker_info == true ]]; then
        worker_ip=$(echo $line | cut -d ' ' -f 1)
        user=$(echo $line | cut -d '=' -f 2)

        echo "Adding host key for $worker_ip to known_hosts"
        ssh-keyscan -H "$worker_ip" >> ~/.ssh/known_hosts

        echo "Copying SSH key to $user@$worker_ip"
        ssh-copy-id -o StrictHostKeyChecking=no "$user@$worker_ip"

        # Create SSH access scripts
        echo "Creating SSH access script for worker$WORKER_COUNT"
        echo "ssh $user@$worker_ip" > "worker$WORKER_COUNT.ssh"
        chmod +x "worker$WORKER_COUNT.ssh"
        WORKER_COUNT=$((WORKER_COUNT+1))
    fi
done < "$HOSTS_FILE"

echo "*************************************"
echo "Installing spark and pyspark locally"
echo "*************************************"

# Check if PySpark is installed and install if it's not
if ! python3 -c "import pyspark" > /dev/null 2>&1; then
    # Set environment variables for Spark
    export SPARK_VERSION=3.5.0
    export HADOOP_VERSION=3
    export SPARK_HOME=/spark
    export PATH=$PATH:$SPARK_HOME/bin
    export SPARK_HISTORY_OPTS="-Dspark.history.ui.port=18080 -Dspark.eventLog.enabled=true -Dspark.eventLog.dir=/tmp/spark-events"
    export SPARK_NO_DAEMONIZE=TRUE

    # Download and install Spark
    mkdir -p /tmp/spark-events
    chmod -R 777 /tmp/spark-events
    wget -q https://downloads.apache.org/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION.tgz
    tar xzf spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION.tgz
    sudo mv spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION /spark
    sudo chmod -R 777 /spark
    rm spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION.tgz

    # Install PySpark and Jupyter
    sudo pip3 install pyspark==$SPARK_VERSION jupyter

    # Set environment variables for Spark
    echo "export SPARK_VERSION=3.5.0" | sudo tee -a /etc/profile
    echo "export HADOOP_VERSION=3" | sudo tee -a /etc/profile
    echo "export SPARK_HOME=/spark" | sudo tee -a /etc/profile
    echo "export PATH=\$PATH:\$SPARK_HOME/bin" | sudo tee -a /etc/profile
    echo "export SPARK_HISTORY_OPTS='-Dspark.history.ui.port=18080 -Dspark.eventLog.enabled=true -Dspark.eventLog.dir=/tmp/spark-events'" | sudo tee -a /etc/profile
    echo "export SPARK_NO_DAEMONIZE=TRUE" | sudo tee -a /etc/profile

fi

echo "*************************************"
echo "completed"
echo "*************************************"

echo "*************************************"
echo "Configuring Spark Master Node"
echo "*************************************"
export SPARK_MASTER_HOST='192.168.50.235'
echo "Setting SPARK_MASTER_HOST to $SPARK_MASTER_HOST"
echo "export SPARK_MASTER_HOST='$SPARK_MASTER_HOST'" | sudo tee -a /spark/conf/spark-env.sh

echo "stopping"
/spark/sbin/stop-master.sh

echo "Starting the Spark master node..."
/spark/sbin/start-master.sh > /dev/null 2>&1 &

/spark/bin/spark-class org.apache.spark.deploy.history.HistoryServer > /dev/null 2>&1 &

echo "*************************************"
echo "Spark Master Node Started"
echo "*************************************"

while true; do
    # Check for the Spark master process
    if ps -ef | grep 'org.apache.spark.deploy.master.Master' | grep -v grep > /dev/null ; then
        echo "Spark master is running."
        break
    else
        echo "Waiting for Spark master to start..."
        sleep 5  # Waits for 5 seconds before checking again
    fi
done

echo "*************************************"
echo "Running ansible playbook"
echo "*************************************"

pip install 

export this_dir=$(pwd)
# Run Ansible Playbook
ansible-playbook -i hosts setup_spark_playbook.yml 

echo "*************************************"
echo "completed"
echo "*************************************"

#!/bin/bash
echo "********************************"
echo "Opening up the chrome tabs"
echo "********************************"

# URLs to open
URL1="http://localhost:8080"
URL2="http://localhost:18080"
URL3="http://localhost:4040"

# Open URLs in new tabs in Google Chrome
google-chrome "$URL1" "$URL2" "$URL3" &
