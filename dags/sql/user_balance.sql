
INSERT INTO user_balance (
  user_id,
  date,
  num_dp_total,
  amount_dp_total,
  num_wd_total, 
  amount_wd_total
)

WITH total_moves as (
	SELECT user_id, date,
       sum(num_dp) AS num_dp_total,
	   sum(total_amount_dp) as amount_dp_total,
       sum(num_wd) as num_wd_total,
	   sum(total_amount_wd) as amount_wd_total
	FROM public.movement_stats
	WHERE date = '{{ ds }}'
	GROUP BY 1,2
)

SELECT u.user_id, 
	   '{{ ds }}' as date,
	   COALESCE(m.num_dp_total,0) as num_dp_total, 
	   COALESCE(m.amount_dp_total,0) as amount_dp_total, 
	   COALESCE(m.num_wd_total,0) as num_wd_total, 
	   COALESCE(m.amount_wd_total,0) as amount_wd_total
FROM users as u
LEFT JOIN total_moves as m
ON u.user_id = m.user_id 
;
