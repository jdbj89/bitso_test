

CREATE TABLE IF NOT EXISTS currencies AS (
    SELECT DISTINCT currency from public.deposit
	UNION
	SELECT DISTINCT currency from public.withdrawals
	ORDER BY 1
);

ALTER TABLE currencies 
ADD PRIMARY KEY (currency);

CREATE TABLE IF NOT EXISTS movement_stats (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(40),
    date DATE,
    currency VARCHAR(10),
    num_dp INTEGER,
    total_amount_dp FLOAT,
	num_wd INTEGER, 
	total_amount_wd FLOAT, 
    CONSTRAINT fk_users
      FOREIGN KEY(user_id) 
	REFERENCES users(user_id)
);

CREATE TABLE IF NOT EXISTS login_stats (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(40),
    date DATE,
    num_login INTEGER,
    last_login TIMESTAMP,
    CONSTRAINT fk_users
      FOREIGN KEY(user_id) 
	REFERENCES users(user_id)
);

CREATE TABLE IF NOT EXISTS user_status (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(40),
    date DATE,
    status VARCHAR(10),
    CONSTRAINT fk_users
      FOREIGN KEY(user_id) 
	REFERENCES users(user_id)
);

CREATE TABLE IF NOT EXISTS user_balance (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(40),
    date DATE,
    num_dp_total INTEGER,
    amount_dp_total FLOAT,
	num_wd_total INTEGER, 
	amount_wd_total FLOAT, 
    CONSTRAINT fk_users
      FOREIGN KEY(user_id) 
	REFERENCES users(user_id)
);

CREATE TABLE IF NOT EXISTS currency_balance (
    id SERIAL PRIMARY KEY,
    currency VARCHAR(10),
    date DATE,
    num_dp_total INTEGER,
    amount_dp_total FLOAT,
	num_wd_total INTEGER, 
	amount_wd_total FLOAT, 
    CONSTRAINT fk_currencies
      FOREIGN KEY(currency) 
	REFERENCES currencies(currency)
);


