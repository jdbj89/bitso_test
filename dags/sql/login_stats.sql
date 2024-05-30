
INSERT INTO login_stats (
  user_id,
  date,
  num_login,
  last_login
)

WITH lastl as(
SELECT user_id,
	   max(event_timestamp) as last_login
	   from public.events
	   where event_name='login'
	   and DATE(event_timestamp)<='{{ ds }}'
	   GROUP BY 1
),

num_l as(
SELECT user_id,
	   DATE(event_timestamp) as date,
	   count(DISTINCT id) as num_login
	   from public.events
	   where event_name='login'
	   and DATE(event_timestamp)='{{ ds }}'
	   GROUP BY 1,2
)

SELECT u.user_id, '{{ ds }}' as date,
	   COALESCE(nl.num_login,0) as num_login, 
	   ll.last_login 
FROM users as u
LEFT JOIN lastl as ll
ON u.user_id = ll.user_id
LEFT JOIN num_l as nl
ON u.user_id = nl.user_id
;
