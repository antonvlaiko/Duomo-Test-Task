WITH ranked_purchases AS (
    -- Знаходимо дату найпершої взаємодії з підпискою для кожного юзера
    SELECT
        user_id,
        product_name,
        DATE(CAST(created_at AS TIMESTAMP)) AS sub_date,
        ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY CAST(created_at AS TIMESTAMP)) as rn
    FROM `data.user_purchases`
),
first_subscription AS (
    -- Залишаємо виключно першу підписку
    SELECT 
        user_id, 
        product_name, 
        sub_date AS first_sub_date
    FROM ranked_purchases
    WHERE rn = 1
),
user_delays AS (
    -- Рахуємо різницю в календарних днях
    SELECT
        fs.user_id,
        fs.product_name,
        DATE_DIFF(fs.first_sub_date, DATE(CAST(u.created_at AS TIMESTAMP)), DAY) AS delay_days
    FROM first_subscription fs
    JOIN `data.users` u ON fs.user_id = u.id
),
valid_users AS (
    -- Залишаємо лише тих, хто вписується у горизонт спостереження 28 днів
    SELECT
        user_id,
        product_name,
        delay_days
    FROM user_delays
    WHERE delay_days BETWEEN 0 AND 28
),
total_base_per_product AS (
    -- Рахуємо окрему 100% базу (знаменник) для кожної підписки!!
    SELECT 
        product_name, 
        COUNT(user_id) AS total_subs_28d
    FROM valid_users
    GROUP BY product_name
),
daily_distribution AS (
    -- Групуємо кількість користувачів по днях і підписках
    SELECT
        product_name,
        delay_days AS day_number,
        COUNT(user_id) AS users_count
    FROM valid_users
    GROUP BY product_name, delay_days
)
-- Фінальний розрахунок відсотків з групуванням по підписках
SELECT
    d.product_name,
    d.day_number,
    d.users_count,
    ROUND((d.users_count * 100.0) / t.total_subs_28d, 2) AS daily_percentage,
    ROUND(SUM(d.users_count * 100.0 / t.total_subs_28d) OVER (PARTITION BY d.product_name ORDER BY d.day_number), 2) AS cumulative_percentage
FROM daily_distribution d
JOIN total_base_per_product t ON d.product_name = t.product_name
ORDER BY d.product_name, d.day_number;
