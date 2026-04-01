/*SELECT
  -- Визначаємо різницю між користувачами та ід-транзакцій
  COUNT(DISTINCT user_id) AS unique_users,
  COUNT(DISTINCT original_transaction_id) AS unique_transactions
FROM `data.user_purchases`
WHERE product_name = '1month_19.99'
  AND is_trial = 0
  AND renewal_number = 1;*/

SELECT 
  -- Визначаємо проблемного користувача
  user_id,
  COUNT(DISTINCT original_transaction_id) AS distinct_subscriptions,
  COUNT(transaction_id) AS total_first_payments,
  STRING_AGG(CAST(original_transaction_id AS STRING), ', ') AS transaction_ids,
  MIN(created_at) AS first_payment_time,
  MAX(created_at) AS last_payment_time
FROM `data.user_purchases`
WHERE product_name = '1month_19.99'
  AND is_trial = 0
  AND renewal_number = 1
GROUP BY user_id
HAVING COUNT(DISTINCT original_transaction_id) > 1;
