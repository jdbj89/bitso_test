
CREATE TABLE IF NOT EXISTS users (
    user_id VARCHAR(40),
    PRIMARY KEY(user_id)
);

CREATE TABLE IF NOT EXISTS deposit (
    id INTEGER,
    event_timestamp TIMESTAMP,
    user_id VARCHAR(40),
    amount FLOAT,
    currency VARCHAR(10),
    tx_status VARCHAR(50),
    PRIMARY KEY(id),
    CONSTRAINT fk_users
      FOREIGN KEY(user_id) 
	  REFERENCES users(user_id)
);

CREATE TABLE IF NOT EXISTS events (
    id INTEGER,
    event_timestamp TIMESTAMP,
    user_id VARCHAR(40),
    event_name VARCHAR(50),
    PRIMARY KEY(id),
    CONSTRAINT fk_users
      FOREIGN KEY(user_id) 
	  REFERENCES users(user_id)
);

CREATE TABLE IF NOT EXISTS withdrawals (
    id INTEGER,
    event_timestamp TIMESTAMP,
    user_id VARCHAR(40),
    amount FLOAT,
    interface VARCHAR(10),
    currency VARCHAR(10),
    tx_status VARCHAR(50),
    PRIMARY KEY(id),
    CONSTRAINT fk_users
      FOREIGN KEY(user_id) 
	  REFERENCES users(user_id)
);
