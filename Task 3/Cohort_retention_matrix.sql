WITH new_users AS (
  -- Визначаємо когорту за першою транзакцією для нових юзерів
  SELECT 
    user_id,
    DATE_TRUNC(DATE(CAST(created_at AS TIMESTAMP)), MONTH) AS cohort_month
  FROM `data.user_purchases`
  WHERE product_name = '1month_19.99'
    AND is_trial = 0
    AND renewal_number = 1
),
cohort_sizes AS (
  -- Фіксуємо початковий розмір кожної когорти
  SELECT 
    cohort_month,
    COUNT(DISTINCT user_id) AS initial_users
  FROM new_users
  GROUP BY cohort_month
),
user_activity AS (
  -- Знаходимо всі місяці оплат і рахуємо індекс
  SELECT DISTINCT
    n.user_id,
    n.cohort_month,
    DATE_DIFF(DATE_TRUNC(DATE(CAST(p.created_at AS TIMESTAMP)), MONTH), n.cohort_month, MONTH) AS month_index
  FROM new_users n
  INNER JOIN `data.user_purchases` p
    ON n.user_id = p.user_id
  WHERE p.product_name = '1month_19.99'
    AND p.is_trial = 0
),
retention_data AS (
  -- Рахуємо збережених користувачів
  SELECT
    cohort_month,
    month_index,
    COUNT(DISTINCT user_id) AS retained_users
  FROM user_activity
  GROUP BY cohort_month, month_index
)
-- Фінальний вивід
SELECT
  FORMAT_DATE('%Y-%m', r.cohort_month) AS cohort,
  s.initial_users AS cohort_size,
  r.month_index,
  FORMAT_DATE('%Y-%m', DATE_ADD(r.cohort_month, INTERVAL r.month_index MONTH)) AS calendar_month_of_action,
  r.retained_users,
  (s.initial_users - r.retained_users) AS churned_users_cumulative,
  ROUND(SAFE_DIVIDE(r.retained_users * 100.0, s.initial_users), 2) AS retention_percentage
FROM retention_data r
INNER JOIN cohort_sizes s ON r.cohort_month = s.cohort_month
ORDER BY r.cohort_month, r.month_index;
