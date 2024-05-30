> # Bitso Data Challenge using S3, Postgres and Airflow

> ## Table of Contents
* [Challenge description](#challenge-description)
* [Proposed Solution](#proposed-solution)
* [Run App - Step by Step](#run-app---step-by-step)
    * [1. Upload data - API](#1-upload-data---api)
    * [2. SQL requests - Endpoints](#2-sql-requests---endpoints)

> ## Challenge description

There are 4 csv, each csv is a snapshot of the for tables deposit, withdrawal, event and user with historic information. 
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
The propose solution for challenge starts storing the 4 csv files in a S3 bucket as is shown in Fig.1.  

![Fig.1. S3 bucket with csv files](https://github.com/jdbj89/bitso_test/blob/main/screen_shots/input_bucket.png?raw=true)

Then, a first Dag called [bitso_cerate_db.py](https://github.com/jdbj89/bitso_test/blob/main/dags/bitso_cerate_db.py) is implemented using Airflow in order to create an initial data base using a Postgres conection, which in this case is pointing to a local postgres server in my local pc. The postgres connection config in Airflow UI is shown below:  

![Fig.2. Postgres Connection](https://github.com/jdbj89/bitso_test/blob/main/screen_shots/postgres_conn.png?raw=true)

>[!NOTE]
>In order to point to the local host of your local PC you have to use **host.docker.internal** in Host field. Also is important to mention that in this case the local postgres server use port 5433, this last because when Airflow runs take as default the port 5432 for the Postgres metadata database and if you have another server in the same port airflow does not start in your local machine and generates an error.

The initial data base is composed by tables deposit, withdrawals, events and users, which are populated by reading the correnponding csv files from S3. For this last I use my owm AWS account and my credentials which must be included in the AWS connection. The AWS connection config in Airflow UI as is shown below:  

![Fig.3. AWS Connection](https://github.com/jdbj89/bitso_test/blob/main/screen_shots/aws_conn.png?raw=true)

The first task of the dag creates the tables, the second task load the data from users csv, this is done first because the other tables are dependent of this due that user_is is a foreign key of the next tables. The next tasks load the data for tables deposit, withdrawal, and event.

>[!WARNING]
>It is important to mention that csv files could contain wrong data, for example in this case there are duplicated data in deposit file. That is why in the import task and preprocessing stage is included in order to delete duplicates data and rows with all values in NULL, this last is not our case but it was included.


The dag graph is shown in Figure 4.  

![Fig.4. Bitso Create DB Dag](https://github.com/jdbj89/bitso_test/blob/main/screen_shots/bitso_create_db.png?raw=true)

Now, having the initial database, which is supposed as a company database created long time ago and updated daily, the next step is create an extra ETL process in order to generate new tables, which will simplify the quering process to get the requested insights. **This ETL will process data daily taking the last day data.**  

The proposed ETL dag is called [bitso_etl.py](https://github.com/jdbj89/bitso_test/blob/main/dags/bitso_etl.py) and its graph is shown below:  

![Fig.5. Bitso ETL Dag](https://github.com/jdbj89/bitso_test/blob/main/screen_shots/bitso_etl.png?raw=true)

The first task of the ETL is just an empty task or starting point of the process, then a branch task is declared which will run the task **create tables** only if it is the first dag run, for posterior executions this task will be skipped. 

The next task populates movements_stats table taking the data of previous day from deposit and withdrwals tables and inserting the result in movements_stats table. Movements_stats table is like a summary of the movements where total of deposits (**num_dp**), total of withdrawals (**num_wd**), total amount of deposits (**total_amount_dp**) and total amount of withdrawals (**total_amount_wd**) are calculated by user_id, date, and currency.

Next, three tasks are calculate in parallel. One of them is user_balance which include all the users from users table and calculate the total of deposits (**num_dp_total**), total of withdrawals (**num_wd_total**), total amount of deposits (**amount_dp_total**) and total amount of withdrawals (**amount_wd_total**) by user and date joining the users table with movements_stats table on user_id. 

Other of the three is currency_balance, which takes all the currency values from currencies table (A table created taking distinct currency values from deposit and withdrwals tables) and calculate the total of deposits (**num_dp_total**), total of withdrawals (**num_wd_total**), total amount of deposits (**amount_dp_total**) and total amount of withdrawals (**amount_wd_total**) by currency and date joining the currencies table with movements_stats table on currency value. 

The othe task is login_stats, which takes all the users from users table and calculate the total of logins of each user by date (**num_login**) and the last time the user made a login (**last_login**) from all historical data until the corresponding date, taking the data from events table. 

Finally, the task user_status takes the info from user_balance table and calculates the **status** of each user for the corresponding date, which will be **ACTIVE** if the user made at least one deposit or one withdrawal, else, it will be **INACTIVE**.


> ## Run Solution

If you want to run this solution in your local enviroment, you just neet to clone this repo, make sure you have installed astro CLI, and then just type in your terminal 
-astro dev start

After this Airflow should start and the next info shoul appear in your terminal 

Airflow Webserver: http://localhost:8080
Postgres Database: localhost:5432/postgres
The default Airflow UI credentials are: admin:admin
The default Postgres DB credentials are: postgres:postgres

