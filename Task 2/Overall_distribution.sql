WITH first_subscription AS (
    -- Знаходимо дату найпершої взаємодії з підпискою для кожного юзера
    SELECT 
        user_id,
        MIN(DATE(CAST(created_at AS TIMESTAMP))) AS first_sub_date
    FROM `data.user_purchases`
    GROUP BY user_id
),
user_delays AS (
    -- Рахуємо різницю в календарних днях між інсталяцією та підпискою
    SELECT 
        fs.user_id,
        DATE_DIFF(fs.first_sub_date, DATE(CAST(u.created_at AS TIMESTAMP)), DAY) AS delay_days
    FROM first_subscription fs
    JOIN `data.users` u ON fs.user_id = u.id
),
valid_users AS (
    -- Залишаємо лише тих, хто вписується у горизонт спостереження 28 днів
    SELECT 
        user_id,
        delay_days
    FROM user_delays
    WHERE delay_days BETWEEN 0 AND 28
),
total_base AS (
    -- Фіксуємо 100% базу для розрахунку для 28 днів
    SELECT COUNT(user_id) AS total_subs_28d
    FROM valid_users
),
daily_distribution AS (
    -- Групуємо кількість користувачів по днях
    SELECT 
        delay_days AS day_number,
        COUNT(user_id) AS users_count
    FROM valid_users
    GROUP BY delay_days
)
-- Фінальний результат із додаванням кумулятивним відсотком
SELECT 
    d.day_number,
    d.users_count,
    ROUND((d.users_count * 100.0) / t.total_subs_28d, 2) AS daily_percentage,
    ROUND(SUM((d.users_count * 100.0) / t.total_subs_28d) OVER (ORDER BY d.day_number), 2) AS cumulative_percentage
FROM daily_distribution d
CROSS JOIN total_base t
ORDER BY d.day_number;
