#!/bin/bash
# Start the Spark history server in the background
/spark/bin/spark-class org.apache.spark.deploy.history.HistoryServer &

# Start Jupyter Notebook in the foreground
exec jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token='' --NotebookApp.password=''
