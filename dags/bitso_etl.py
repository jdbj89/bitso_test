"""
## Bitso ETL Dag

This DAG creates the initial database on postgres

"""
import os
import pandas as pd
from io import BytesIO
from airflow.decorators import dag, task
from airflow.models import Variable
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.operators.empty import EmptyOperator
from pendulum import datetime

var = Variable.get("bitso_etl_var", deserialize_json=True)

filenames = ['user_id_sample_data', 'deposit_sample_data', 'event_sample_data', 'withdrawals_sample_data']
tables = ['users', 'deposit', 'events', 'withdrawals']

S3_hook = S3Hook(aws_conn_id='aws_conn')
bucket='bitso-data'
path_cwd = os.getcwd()

# Define the basic parameters of the DAG, like schedule and start_date
@dag(
    start_date=datetime(2020, 1, 2),
    end_date=datetime(2023, 8, 23),
    schedule="@daily",
    catchup=True,
    max_active_runs=1,
    doc_md=__doc__,
    default_args={"owner": "jd_bolanos", "retries": 3},
    tags=["Bitso"],
)
def bitso_etl_dag():
    # Define tasks

    start = EmptyOperator(task_id='start')

    @task.branch()
    def branching(flag):
        if flag:
            return 'create_etl_tables'
        else:
            return 'movements_stats'
    
    choice_instance = branching(var['first_time'])

    create_etl_tables = PostgresOperator(
        task_id='create_etl_tables',
        postgres_conn_id='postgres_conn_local',
        sql='sql/create_etl_tables.sql'
    )

    movements_stats = PostgresOperator(
        task_id='movements_stats',
        postgres_conn_id='postgres_conn_local',
        sql='sql/movements_stats.sql',
        trigger_rule='none_failed_or_skipped'
    )

    login_stats = PostgresOperator(
        task_id='login_stats',
        postgres_conn_id='postgres_conn_local',
        sql='sql/login_stats.sql'
    )

    user_balance = PostgresOperator(
        task_id='user_balance',
        postgres_conn_id='postgres_conn_local',
        sql='sql/user_balance.sql'
    )

    currency_balance = PostgresOperator(
        task_id='currency_balance',
        postgres_conn_id='postgres_conn_local',
        sql='sql/currency_balance.sql'
    )

    user_status = PostgresOperator(
        task_id='user_status',
        postgres_conn_id='postgres_conn_local',
        sql='sql/active_user.sql'
    )

    start >> choice_instance >> create_etl_tables
    choice_instance >> create_etl_tables
    create_etl_tables >> movements_stats >> user_balance >> user_status
    choice_instance >> movements_stats >> user_balance >> user_status
    movements_stats >> [login_stats, currency_balance]

# Instantiate the DAG
bitso_etl_dag()
