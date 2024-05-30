
INSERT INTO movement_stats (
  user_id,
  date,
  currency,
  num_dp,
  total_amount_dp,
	num_wd, 
	total_amount_wd 
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

SELECT COALESCE(d.user_id, w.user_id) as user_id,
       '{{ ds }}' as date,
       COALESCE(d.currency, w.currency) as currency,
       COALESCE(d.num_deposits,0) as num_dp, 
	     COALESCE(d.total_amount,0) as total_amount_dp, 
	     COALESCE(w.num_withdrawals,0) as num_wd, 
	     COALESCE(w.total_amount,0) as total_amount_wd
from deposits as d
FULL OUTER JOIN withdrawals as w
ON d.user_id = w.user_id and d.currency = w.currency
;
