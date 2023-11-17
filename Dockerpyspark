# Start from OpenJDK base image
FROM openjdk:11-jre-slim

# Install Python
RUN apt-get update && \
    apt-get install -y python3 python3-pip wget && \
    apt-get clean;

# Set environment variables for Spark
ENV SPARK_VERSION=3.5.0
ENV HADOOP_VERSION=3
ENV SPARK_HOME=/spark
ENV PATH=$PATH:$SPARK_HOME/bin

# Download and install Spark
RUN wget -q https://downloads.apache.org/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION.tgz && \
    tar xzf spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION.tgz && \
    mv spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION /spark && \
    rm spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION.tgz

# Install PySpark and Jupyter
RUN pip3 install pyspark==$SPARK_VERSION jupyter

# Expose the port Jupyter will run on
EXPOSE 8888

# Set the working directory in the container
WORKDIR /workspace

# Start Jupyter Notebook
CMD ["jupyter", "notebook", "--ip='*'", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''", "--NotebookApp.password=''"]
