
sudo cp -r ./out/*.* /sparkcluster/fileshare

chmod -R 777 /sparkcluster/fileshare

SPARK_MASTER_HOST='192.168.50.235'

spark-submit \
  --master spark://$SPARK_MASTER_HOST:7077 \
  --deploy-mode client \
  --executor-memory 2G \
  --total-executor-cores 2 \
  $(pwd)/spark_submit_cluster.py

