# Customer Churn & Cohort Retention Analytics

## Project Overview & Objective
Customer churn is a critical leak in any transactional or subscription-based ecosystem. However, traditional static evaluations often oversimplify user behavior by treating customer lifecycles as binary (active vs. dead). 

The objective of this project is to deploy an end-to-end analytical framework that builds a **dynamic, transaction-level behavior model**. By evaluating sequential purchase histories, this project calculates overall retention, identifies hidden behavioral states like user "resurrection," and maps month-over-month cohort decay matrices to find exactly where customer drops occur.

---

## Core Business Questions Answered
1. **The Ultimate Churn State:** What percentage of our customer base has completely abandoned the platform (defined as 30+ days of total inactivity following their final transaction)?
2. **Behavioral Transitions (Resurrected Users):** How often do lapsed customers experience a "break" in activity but successfully return to place another order later?
3. **Cohort Velocity Matrix:** When grouping users by their initial signup month, what percentage return to purchase in Month 1, Month 2, and Month 3?
4. **Channel Acquisition ROI:** Which acquisition channels (Google Ads, Organic Search, Referral) are bringing in the highest-fidelity, longest-lasting cohorts?

---

## Technical Skills Demonstrated
*   **Advanced SQL Window Functions:** Leveraging `LAG() OVER (PARTITION BY... ORDER BY...)` to capture chronological intervals between sequential events.
*   **Dynamic Rank Filtering:** Utilizing `ROW_NUMBER() DESC` to isolate a user’s absolute final transaction relative to a shifting timeline.
*   **Common Table Expressions (CTEs):** Building multi-layered, modular CTE segments to process complex event streams cleanly.
*   **Time-Series Analysis & Dimensional Modeling:** Using `DATE_TRUNC`, `EXTRACT`, and `AGE` intervals to build flexible cohort grids.

---

## Database Schema & Architecture
The underlying database utilizes a streamlined, performance-optimized relational structure:

### 1. `users` (Dimension Table)
*   `user_id` (INT, Primary Key): Unique customer identifier.
*   `signup_date` (DATE): Account creation timestamp.
*   `acquisition_channel` (VARCHAR): The marketing source responsible for bringing in the user.

### 2. `orders` (Fact Table)
*   `order_id` (INT, Primary Key): Unique transaction identifier.
*   `user_id` (INT, Foreign Key): Relation linking directly back to the `users` table.
*   `order_date` (DATE): Transaction date.
*   `order_amount` (DECIMAL): Monetary value of the order.

---

## Analytical Insights & Executive Summary

### 1. User Interval Transitions (The "Resurrection" Metric)
*   **Insight:** The `LAG()` window analysis indicates that a notable portion of our consumer base goes through an "inactive" phase before buying again. Instead of traditional "Dead Churn," these users fall under the **Lapsed but Resurrected** flag.
*   **Actionable Impact:** Treating these users as completely lost is a mistake. Marketing teams should shift spending away from expensive cold-user acquisition and put it toward re-engagement triggers to speed up the resurrection cycle.

### 2. Month-over-Month Cohort Decay Grid
*   **Insight:** Looking across our historical data, a steep drop-off occurs consistently in the transition from **Month 0 to Month 1**. For most cohorts, retention rates fall by more than 50% immediately following registration.
*   **Recommendation:** Product teams must implement a structured onboarding drip campaign or a secondary conversion incentive within the first 14 days post-signup to smooth out this early-lifecycle drop-off.

---

## How to Run this Project

### Prerequisites
*   A relational database engine supporting ANSI SQL Window Functions (written and optimized for **PostgreSQL**).

### Execution Steps
1. Clone this repository to your machine.
2. Open your preferred database workspace GUI (e.g., pgAdmin, DBeaver).
3. Open and execute the script inside `customer_churn_cohort_analysis.sql` from top to bottom. The script creates the schemas, seeds longitudinal user behavior records, and outputs the finished evaluation matrices.
