#!/bin/bash

cd ./cluster_setup && . uninstall_spark_master_and_nodes.sh && . setup_master_with_ufw.sh && cd ./../ && . sparksubmit.sh
