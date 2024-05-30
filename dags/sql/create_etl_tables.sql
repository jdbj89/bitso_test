CREATE TABLE IF NOT EXISTS currencies AS (
    SELECT DISTINCT currency from public.deposit
	UNION
	SELECT DISTINCT currency from public.withdrawals
	ORDER BY 1
);

CREATE TABLE IF NOT EXISTS movement_stats (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(40),
    date DATE,
    currency VARCHAR(10),
    num_dp INTEGER,
    total_amount_dp FLOAT,
	num_wd INTEGER, 
	total_amount_wd FLOAT, 
    status VARCHAR(10),
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

