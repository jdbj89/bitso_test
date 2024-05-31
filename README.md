> # Bitso Data Challenge using S3, Postgres and Airflow

> ## Table of Contents
* [Challenge description](#challenge-description)
* [Proposed Solution](#proposed-solution)
* [Run App - Step by Step](#run-solution---step-by-step)


> ## Challenge description

For this challenges 4 csv files were shared in this [link](https://drive.google.com/drive/folders/18cIw7TWMCrrN6MgfrKmD4IrSWsyltjfx), each csv is a snapshot of the tables deposit, withdrawal, event and user with historic information. 
The main objective of challenge is provide master data for the downstream users Business Intelligence, Machine Learning, Experimentation and Marketing. 
These teams will use the data for multiple purposes, the tables and data model you’ll create should help them answer questions like the following:


How many users were active on a given day (they made a deposit or withdrawal)  
Identify users haven't made a deposit  
Identify on a given day which users have made more than 5 deposits historically  
When was the last time a user made a login  
How many times a user has made a login between two dates  
Number of unique currencies deposited on a given day  
Number of unique currencies withdrew on a given day  
Total amount deposited of a given currency on a given day  

> ## Proposed Solution

The propose solution for challenge starts storing the 4 csv files in a S3 bucket as is shown in the next figure. 

![Fig.1. S3 bucket with csv files](https://github.com/jdbj89/bitso_test/blob/main/screen_shots/input_bucket.png?raw=true)

Then, a first Dag called [bitso_create_db.py](https://github.com/jdbj89/bitso_test/blob/main/dags/bitso_create_db.py) is implemented using Airflow in order to create an initial data base using a Postgres conection, which in this case is pointing to a local postgres server in my local pc where a database called bitso_data was created previously. The postgres connection config in Airflow UI is shown below:  

![Fig.2. Postgres Connection](https://github.com/jdbj89/bitso_test/blob/main/screen_shots/postgres_conn.png?raw=true)

>[!NOTE]
>In order to point to the localhost of your local PC you have to use **host.docker.internal** in Host field. Also is important to mention that in this case the local postgres server use port 5433, this last because Airflow takes as default the port 5432 for the Postgres metadata database and if you have another server in the same port Airflow will not start in your local machine and will generate an error.

The initial data base is composed by tables deposit, withdrawals, events and users, which are populated by reading the correnponding csv files from S3. For this last I used my personal AWS account. Credentials info must be included in the AWS connection. The AWS connection config in Airflow UI is shown below:  

![Fig.3. AWS Connection](https://github.com/jdbj89/bitso_test/blob/main/screen_shots/aws_conn.png?raw=true)

The first task of the dag creates the tables in the postgres database, the second task load the data from users csv file, this is done first because the other tables are dependent of users table, this due that user_id is a foreign key in next tables. The next tasks load the data for tables deposit, withdrawals, and events.

>[!WARNING]
>It is important to mention that csv files could contain wrong data, for example in this case there are duplicated data in deposit file. That is why a preprocessing stage is included in the import task in order to delete duplicates data and rows with all values in NULL, this last is not our case but it was included.


The bitso_create_db dag graph is shown below.  

![Fig.4. Bitso Create DB Dag](https://github.com/jdbj89/bitso_test/blob/main/screen_shots/bitso_create_db.png?raw=true)

Now, having the initial database, which is supposed as a company database created long time ago and updated daily, the next step is create an extra ETL process in order to generate new tables, which will simplify the quering process to get the requested insights. **This ETL will process data daily taking the last day data.**  

The proposed ETL dag is called [bitso_etl.py](https://github.com/jdbj89/bitso_test/blob/main/dags/bitso_etl.py) and its graph is shown below:  

![Fig.5. Bitso ETL Dag](https://github.com/jdbj89/bitso_test/blob/main/screen_shots/bitso_etl.png?raw=true)

The first task of the ETL is just an empty task or starting point of the process, then a branch task is declared which will run the task **create etl tables** only if it is the first dag_run, for posterior executions this task will be skipped. 

After create etl tables task, we already have the final structure of our database. The database ERD is shown below.

![Fig.6. Database ERD](https://github.com/jdbj89/bitso_test/blob/main/screen_shots/ERD.png?raw=true)


The next task populates **movements_stats table** taking the data of previous day from deposit and withdrwals tables. Movements_stats table is like a summary of the movements where total of deposits (**num_dp**), total of withdrawals (**num_wd**), total amount of deposits (**total_amount_dp**) and total amount of withdrawals (**total_amount_wd**) are calculated by user_id, date, and currency.

Next, three tasks are calculate in parallel. One of them is user_balance which include all the users from users table and calculate the total of deposits (**num_dp_total**), total of withdrawals (**num_wd_total**), total amount of deposits (**amount_dp_total**) and total amount of withdrawals (**amount_wd_total**) by user and date. This is done joining the users table with movements_stats table using user_id as key. 

Other of the three tasks is currency_balance, which takes all the currency values from currencies table (A table created taking distinct currency values from deposit and withdrwals tables) and calculate the total of deposits (**num_dp_total**), total of withdrawals (**num_wd_total**), total amount of deposits (**amount_dp_total**) and total amount of withdrawals (**amount_wd_total**) by currency and date joining the currencies table with movements_stats table using currency value as key. 

The other task is login_stats, which takes all the users from users table and calculate the total of logins of each user by date (**num_login**) and the last time the user made a login (**last_login**), this last taking all historical data until the corresponding date. Those two values are calculated taking the data from events table. 

Finally, the task user_status takes the info from user_balance table and calculates the **status** of each user for the corresponding date, which will be **ACTIVE** if the user made at least one deposit or one withdrawal, else, it will be **INACTIVE**.

The bitso_etl dag runs daily. In this case it is configure to backfilling previous dates starting in 2020-01-02 date. For this specific case an end date was also configured as 2023-08-23. Those two dates were the minimum and maximun dates from deposit and withdrawals tables. For a production approach the end date must be ommitted.


> ## Run Solution - Step by Step

If you want to run this solution in your local enviroment, you just need to follow next steps:

1. Install Postgres
2. Configure a postgres Server using port **5433** and create DB called **bitso_data**
3. Download csv files from this [link](https://drive.google.com/drive/folders/18cIw7TWMCrrN6MgfrKmD4IrSWsyltjfx) and store it in S3 (AWS personal account)
3. Install docker and astro CLI
4. Clone this repo
5. Type **astro dev start** in your terminal
6. After few minutes this message should appears in your terminal, which indicates that Airflow is working and UI is running on http://localhost:8080

```
Airflow Webserver: http://localhost:8080  
Postgres Database: localhost:5432/postgres  
The default Airflow UI credentials are: admin:admin  
The default Postgres DB credentials are: postgres:postgres
```

7. Configure the Postgres and AWS connections in Airflow UI as it was shown above
8. Activate dag bitso_create_dag and run it just one time
9. Deactivate previous dag and active bitso_etl_dag, keep this last active because it will execute one time by each date since 2020-01-02 to 2023-08-23

After these step Airflow UI should looks like the next figure.

![Fig.6. Dags](https://github.com/jdbj89/bitso_test/blob/main/screen_shots/dags.png?raw=true)
