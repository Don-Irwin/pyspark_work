import csv
import os
import random
import string
from datetime import datetime, timedelta

def random_string(length=10):
    """Generate a random string of fixed length."""
    return ''.join(random.choice(string.ascii_lowercase) for _ in range(length))

def random_date(start, end):
    """Generate a random datetime between `start` and `end`."""
    return start + timedelta(
        seconds=random.randint(0, int((end - start).total_seconds())),
    )

def generate_csv(filename, size_limit=1024**3):
    """Generate a CSV file with a target size limit."""
    with open(filename, 'w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['id', 'name', 'timestamp', 'value'])

        total_size = 0
        id_counter = 1
        start_date = datetime(2020, 1, 1)
        end_date = datetime(2023, 1, 1)

        while total_size < size_limit:
            row = [
                id_counter,
                random_string(10),
                random_date(start_date, end_date).strftime('%Y-%m-%d %H:%M:%S'),
                random.uniform(0, 1000)
            ]
            writer.writerow(row)
            id_counter += 1
            total_size = file.tell()

generate_csv('sample_data_to_transform.csv')
