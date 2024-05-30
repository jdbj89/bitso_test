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
def bitso_etl_dag():
    # Define tasks

    create_etl_tables = PostgresOperator(
        task_id='create_etl_tables',
        postgres_conn_id='postgres_conn_local',
        sql='sql/create_etl_tables.sql'
    )

    movements_stats = PostgresOperator(
        task_id='movements_stats',
        postgres_conn_id='postgres_conn_local',
        sql='sql/movements_stats.sql'
    )

    login_stats = PostgresOperator(
        task_id='login_stats',
        postgres_conn_id='postgres_conn_local',
        sql='sql/login_stats.sql'
    )

    user_status = PostgresOperator(
        task_id='user_status',
        postgres_conn_id='postgres_conn_local',
        sql='sql/active_user.sql'
    )

    create_etl_tables >> [movements_stats, login_stats]
    movements_stats >> user_status


# Instantiate the DAG
bitso_etl_dag()
