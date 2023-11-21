#!/bin/bash

SPARK_MASTER_HOST='192.168.50.235'

cp ./../spark_submit_cluster.py ./

spark-submit \
  --master spark://$SPARK_MASTER_HOST:7077 \
  --deploy-mode client \
  --executor-memory 2G \
  --total-executor-cores 4 \
  --py-files $(pwd)/external.zip, $(pwd)/libraries.zip \
  $(pwd)/spark_submit_cluster.py

rm -rf spark_submit_cluster.py