"""
## Bitso ETL Dag

This DAG creates the initial database on postgres

"""
import os
import pandas as pd
from io import BytesIO
from airflow.decorators import dag, task
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from pendulum import datetime


filenames = ['user_id_sample_data', 'deposit_sample_data', 'event_sample_data', 'withdrawals_sample_data']
tables = ['users', 'deposit', 'events', 'withdrawals']

S3_hook = S3Hook(aws_conn_id='aws_conn')
bucket='bitso-data'
path_cwd = os.getcwd()

# Define the basic parameters of the DAG, like schedule and start_date
@dag(
    start_date=datetime(2024, 1, 1),
    schedule="@daily",
    catchup=False,
    doc_md=__doc__,
    default_args={"owner": "jd_bolanos", "retries": 3},
    tags=["Bitso"],
)
def bitso_create_db_dag():
    # Define tasks

    @task
    def import_csv(file_name, table):
        
        temp_path=f'/dags/csv/temp_{file_name}.csv'
        temp_fullpath=path_cwd+temp_path

        key=file_name+'.csv'
        obj=S3_hook.get_key(key, bucket)

        df = pd.read_csv(BytesIO(obj.get()['Body'].read()))
        print(df.head(10))
        df = df.drop_duplicates()
        df.dropna(axis=0, how="all", inplace=True)
        df.reset_index(drop=True, inplace=True)
        df.to_csv(temp_fullpath, index=False)

        pg_hook = PostgresHook(postgres_conn_id='postgres_conn_local', database='bitso_data')
        sql=f"COPY public.{table} FROM STDIN WITH DELIMITER ',' CSV HEADER;"
        pg_hook.copy_expert(sql, temp_fullpath)
        os.remove(temp_fullpath)


    create_table = PostgresOperator(
        task_id='create_table_task',
        postgres_conn_id='postgres_conn_local',
        sql='sql/create_tables.sql'
    )

    for i in range(len(tables)):
        if i==0:
            import_user=import_csv.override(task_id=f'import_{tables[i]}')(filenames[i], tables[i])
            create_table >> import_user
        else:
            import_task=import_csv.override(task_id=f'import_{tables[i]}')(filenames[i], tables[i])
            import_user >> import_task

# Instantiate the DAG
bitso_create_db_dag()
