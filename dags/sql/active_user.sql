
INSERT INTO user_status (
  user_id,
  date,
  status
)

WITH TOTAL AS (
    SELECT user_id, date,
           sum(num_dp) AS total_dp,
           sum(num_wd) as total_wd
    FROM public.movement_stats
    WHERE date = '{{ ds }}'
    GROUP BY 1,2
)

SELECT user_id, date,
       CASE WHEN total_dp>0 OR total_wd>0 THEN 'ACTIVE'
       ELSE 'INACTIVE' END AS status
FROM TOTAL;
