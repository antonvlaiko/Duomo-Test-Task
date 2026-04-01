WITH max_date_cte AS (
    -- Знаходимо максимальну дату в усьому датасеті
    SELECT MAX(DATE(CAST(created_at AS TIMESTAMP))) AS max_dataset_date
    FROM `data.user_purchases`
),
trial_starts AS (
    -- Беремо лише ті тріали, які гарантовано мали 3 дні на завершення
    SELECT DISTINCT original_transaction_id
    FROM `data.user_purchases`
    CROSS JOIN max_date_cte
    WHERE is_trial = 1
      AND product_name LIKE '%trial%' -- для точності 
      AND DATE(CAST(created_at AS TIMESTAMP)) <= DATE_SUB(max_date_cte.max_dataset_date, INTERVAL 3 DAY)
),
paid_conversions AS (
    -- Обираємо перші списання після тріалу
    SELECT DISTINCT original_transaction_id
    FROM `data.user_purchases`
    WHERE is_trial = 0
      AND renewal_number = 1
      AND product_name LIKE '%trial%'
)
SELECT
    COUNT(DISTINCT ts.original_transaction_id) AS total_trials,
    COUNT(DISTINCT pc.original_transaction_id) AS converted_to_paid,
    ROUND(COUNT(DISTINCT pc.original_transaction_id) * 100.0
        / NULLIF(COUNT(DISTINCT ts.original_transaction_id), 0), 2) AS conversion_rate_percentage
FROM trial_starts ts
LEFT JOIN paid_conversions pc
    ON ts.original_transaction_id = pc.original_transaction_id;
