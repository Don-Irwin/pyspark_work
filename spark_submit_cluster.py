import pandas as pd
from external.db_and_excel_utilities.utility import Utility as mutil
from external.db_and_excel_utilities.db_base import db_base
import os
u = mutil()
import os
import time
from pyspark.sql import SparkSession

def split_file_and_save_parts():
    # Initialize Spark session with logging configuration
    spark = SparkSession.builder \
        .appName("SplitFile") \
        .config("spark.eventLog.enabled", "true") \
        .config("spark.eventLog.dir", "file:///tmp/spark-events") \
        .getOrCreate()
    # Start the timer
    start_time = time.time()

    # Read the file into an RDD
    file_path = "/sparkcluster/fileshare/sample_data_to_transform.csv";
    file_rdd = spark.sparkContext.textFile(file_path)

    # Calculate the number of lines per part
    total_lines = file_rdd.count()
    lines_per_part = total_lines // 4

    # Function to save each part
    def save_part(index):
        part_rdd = file_rdd.zipWithIndex().filter(lambda x: index*lines_per_part <= x[1] < (index+1)*lines_per_part if index < 3 else x[1] >= index*lines_per_part).keys()
        part_data = part_rdd.collect()  # Collects data to the driver node

        part_file_path = f"/sparkcluster/fileshare/part_{index}.txt";
        u.nukepath(part_file_path)
        u.nukefile(part_file_path)        
        with open(part_file_path, 'w') as file:
            for line in part_data:
                file.write(line + '\n')

    # Save each part
    for i in range(4):
        save_part(i)

    # Stop the Spark session
    spark.stop()

    # Stop the timer and calculate elapsed time
    end_time = time.time()
    elapsed_time = end_time - start_time

    # Convert elapsed time to minutes and seconds
    minutes = int(elapsed_time // 60)
    seconds = int(elapsed_time % 60)
    
    print(f"Time elapsed: {minutes} minutes and {seconds} seconds")
    print(u.get_this_dir())

# Call the function
split_file_and_save_parts()
