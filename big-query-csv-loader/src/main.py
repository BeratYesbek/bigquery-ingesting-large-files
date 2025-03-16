import os
from google.cloud import bigquery, storage
from smart_open import open
from model import Users
import logging
import csv
import itertools

PROJECT_ID = "beratyesbek-test"
DATASET_ID = "users_dataset"
TABLE_ID = "users"

def main():
    bucket_name = os.environ.get("INPUT_BUCKET")
    file_name = os.environ.get("INPUT_FILE")
    start_process(bucket_name, file_name)


def start_process(bucket_name, file_name):
    uri = f"gs://{bucket_name}/{file_name}"
    with open(uri, "r") as blob_stream:
        reader = csv.DictReader(blob_stream)
        for batch in itertools.batched(reader, 10000):
            process_batch(batch)
    logging.info(f"Data loaded from {uri} to BigQuery table {PROJECT_ID}.{DATASET_ID}.{TABLE_ID}")

def process_batch(batch: tuple):
    data_object = []
    for row in batch:
        object = Users.model_validate(row, strict=False)
        data_object.append(object.model_dump())
    save_bigquery(data_object)
    data_object.clear()

def save_bigquery(objects):
    client = bigquery.Client(project=PROJECT_ID)
    table = client.get_table(f"{DATASET_ID}.{TABLE_ID}")
    client.insert_rows_json(table, objects)
    logging.info(f"Data loaded to BigQuery table {PROJECT_ID}.{DATASET_ID}.{TABLE_ID}")
        

if __name__ == '__main__':
    main()