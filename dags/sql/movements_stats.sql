
INSERT INTO movement_stats (
  user_id,
  date,
  currency,
  num_dp,
  total_amount_dp,
	num_wd, 
	total_amount_wd, 
  status
)

WITH deposits as (
SELECT user_id, 
	   DATE(event_timestamp) as date,
     currency, 
	   COUNT(DISTINCT id) as num_deposits,
	   SUM(amount) as total_amount
	from public.deposit
	WHERE amount IS NOT NULL and amount >0
	AND DATE(event_timestamp)='{{ ds }}'
	GROUP BY 1,2,3
),

withdrawals as (
	SELECT user_id, 
	   DATE(event_timestamp) as date, 
     currency,
	   COUNT(DISTINCT id) as num_withdrawals,
	   SUM(amount) as total_amount
	from public.withdrawals
	WHERE amount IS NOT NULL and amount >0
	AND DATE(event_timestamp)='{{ ds }}'
	GROUP BY 1,2,3
)

SELECT u.user_id, '{{ ds }}' as date,
      c.currency,
	   COALESCE(d.num_deposits,0) as num_dp, 
	   COALESCE(d.total_amount,0) as total_amount_dp, 
	   COALESCE(w.num_withdrawals,0) as num_wd, 
	   COALESCE(w.total_amount,0) as total_amount_wd, 
     CASE WHEN COALESCE(d.num_deposits,0)>0 OR COALESCE(w.num_withdrawals,0)>0 THEN 'ACTIVE'
     ELSE 'INACTIVE' END AS status
FROM users as u
JOIN currencies as c ON 1=1
LEFT JOIN deposits as d
ON u.user_id = d.user_id and c.currency = d.currency
LEFT JOIN withdrawals as w
ON u.user_id = w.user_id and c.currency = w.currency
;
