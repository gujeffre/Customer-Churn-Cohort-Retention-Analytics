-- =========================================================================
-- PORTFOLIO PROJECT: CUSTOMER CHURN & COHORT RETENTION ANALYSIS
-- DIALECT: PostgreSQL (Standard ANSI SQL compatible with most platforms)
-- DESCRIPTION: Resolving critical business questions around user lifecycle, 
--              identifying exact churn points, and computing cohort retention.
-- =========================================================================

---------------------------------------------------------------------------
-- STEP 1: SCHEMA SETUP & MOCK DATA POPULATION
---------------------------------------------------------------------------

-- Create the baseline users table
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    signup_date DATE NOT NULL,
    acquisition_channel VARCHAR(50)
);

-- Create the orders transaction table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    order_date DATE NOT NULL,
    order_amount DECIMAL(10, 2)
);

-- Insert realistic longitudinal user behavior data
INSERT INTO users (user_id, signup_date, acquisition_channel) VALUES
(1, '2026-01-15', 'Google Ads'),
(2, '2026-01-20', 'Organic Search'),
(3, '2026-01-22', 'Referral'),
(4, '2026-02-05', 'Google Ads'),
(5, '2026-02-18', 'Social Media'),
(6, '2026-03-01', 'Organic Search');

INSERT INTO orders (order_id, user_id, order_date, order_amount) VALUES
-- User 1: Active, consistent purchases
(101, 1, '2026-01-15', 50.00),
(102, 1, '2026-02-14', 35.50),
(103, 1, '2026-03-20', 60.00),
(104, 1, '2026-04-18', 42.00),

-- User 2: Churned early after second purchase
(105, 2, '2026-01-20', 100.00),
(106, 2, '2026-02-02', 20.00),

-- User 3: Instant churn (single purchase, never returned)
(107, 3, '2026-01-22', 15.00),

-- User 4: Active across multiple months
(108, 4, '2026-02-05', 45.00),
(109, 4, '2026-03-10', 55.00),
(110, 4, '2026-04-12', 30.00),

-- User 5: Late churned
(111, 5, '2026-02-18', 80.00),
(112, 5, '2026-03-15', 75.00),

-- User 6: New user, single initial transaction
(113, 6, '2026-03-01', 120.00);


---------------------------------------------------------------------------
-- STEP 2: METRIC 1 - CUSTOMER CHURN ANALYSIS (Window Functions & LAG)
-- BUSINESS LOGIC: A customer is "Churned" if they have not ordered for > 30 days. 
--                 If they have returned since, they are tagged as "Resurrected".
---------------------------------------------------------------------------

WITH ordered_intervals AS (
    SELECT 
        order_id,
        user_id,
        order_date,
        -- Fetch the previous order date for this specific customer
        LAG(order_date) OVER (
            PARTITION BY user_id 
            ORDER BY order_date
        ) AS previous_order_date,
        -- Check if this is the customer's absolute final transaction on record
        ROW_NUMBER() OVER (
            PARTITION BY user_id 
            ORDER BY order_date DESC
        ) AS recency_rank
    FROM orders
),
days_between_calculations AS (
    SELECT 
        order_id,
        user_id,
        order_date,
        previous_order_date,
        recency_rank,
        (order_date - previous_order_date) AS days_since_last_order,
        -- If their final order was over 30 days ago from "current date" (Assume April 30, 2026)
        ('2026-04-30'::DATE - order_date) AS days_since_final_order
    FROM ordered_intervals
)
SELECT 
    user_id,
    order_date AS evaluation_order_date,
    days_since_last_order,
    CASE 
        WHEN recency_rank = 1 AND days_since_final_order > 30 THEN 'Dead Churn (Left Platform)'
        WHEN days_since_last_order > 30 THEN 'Lapsed but Resurrected'
        ELSE 'Active / Healthy Interval'
    END AS customer_status
FROM days_between_calculations
ORDER BY user_id, order_date;


---------------------------------------------------------------------------
-- STEP 3: METRIC 2 - COHORT RETENTION MATRIX (CTEs & Cohort Multi-Joins)
-- BUSINESS LOGIC: Track user sign-up groups (Months) and measure what % 
--                 return to purchase in Month 0, Month 1, Month 2, etc.
---------------------------------------------------------------------------

WITH user_cohorts AS (
    -- Establish the baseline "Cohort Month" for each customer
    SELECT 
        user_id,
        DATE_TRUNC('month', signup_date)::DATE AS cohort_month
    FROM users
),
user_activities AS (
    -- Determine every unique month each customer made a purchase
    SELECT DISTINCT
        user_id,
        DATE_TRUNC('month', order_date)::DATE AS activity_month
    FROM orders
),
cohort_sizes AS (
    -- Calculate total unique starting users per cohort month (Denominator)
    SELECT 
        cohort_month,
        COUNT(DISTINCT user_id) AS total_users
    FROM user_cohorts
    GROUP BY cohort_month
),
retention_intervals AS (
    -- Join cohorts and activities to compute the index distance in months
    SELECT 
        c.cohort_month,
        s.total_users,
        -- Calculate how many months after signing up the transaction occurred
        EXTRACT(YEAR FROM AGE(a.activity_month, c.cohort_month)) * 12 +
        EXTRACT(MONTH FROM AGE(a.activity_month, c.cohort_month)) AS period_month_index,
        COUNT(DISTINCT a.user_id) AS active_users_in_period
    FROM user_cohorts c
    JOIN user_activities a ON c.user_id = a.user_id
    JOIN cohort_sizes s ON c.cohort_month = s.cohort_month
    GROUP BY c.cohort_month, s.total_users, period_month_index
)
-- Build the final pivot table matrix showing retention percentages
SELECT 
    TO_CHAR(cohort_month, 'YYYY-MM') AS cohort,
    total_users AS starting_size,
    MAX(CASE WHEN period_month_index = 0 THEN ROUND((active_users_in_period::NUMERIC / total_users) * 100, 1) ELSE 0 END) AS month_0_pct,
    MAX(CASE WHEN period_month_index = 1 THEN ROUND((active_users_in_period::NUMERIC / total_users) * 100, 1) ELSE 0 END) AS month_1_pct,
    MAX(CASE WHEN period_month_index = 2 THEN ROUND((active_users_in_period::NUMERIC / total_users) * 100, 1) ELSE 0 END) AS month_2_pct,
    MAX(CASE WHEN period_month_index = 3 THEN ROUND((active_users_in_period::NUMERIC / total_users) * 100, 1) ELSE 0 END) AS month_3_pct
FROM retention_intervals
GROUP BY cohort_month, total_users
ORDER BY cohort_month;