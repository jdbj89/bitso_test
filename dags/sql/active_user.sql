
INSERT INTO user_status (
  user_id,
  date,
  status
)

SELECT user_id, date,
       CASE WHEN num_dp_total>0 OR num_wd_total>0 THEN 'ACTIVE'
       ELSE 'INACTIVE' END AS status
FROM user_balance
WHERE date = '{{ ds }}';
