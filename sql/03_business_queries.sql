
CREATE TABLE loan_applications (
    customer_id INT PRIMARY KEY,
    age NUMERIC(5,1),
    gender VARCHAR(20),
    marital_status VARCHAR(20),
    education_level VARCHAR(20),
    annual_income NUMERIC(12,2),
    loan_amount NUMERIC(12,2),
    credit_score NUMERIC(6,1),
    employment_years NUMERIC(5,1),
    employment_type VARCHAR(30),
    loan_purpose VARCHAR(30),
    home_ownership VARCHAR(20),
    debt_to_income_ratio NUMERIC(5,3),
    existing_loans NUMERIC(5,1),
    loan_term_months NUMERIC(6,1),
    interest_rate NUMERIC(5,2),
    loan_status VARCHAR(20),
    application_date DATE,
    application_year NUMERIC(6,1),
    application_month NUMERIC(4,1),
    income_bracket VARCHAR(30),
    credit_score_band VARCHAR(20)
);


--  Total row count (should be 9324)
SELECT COUNT(*) FROM loan_applications;

-- Approval/rejection split (should match: Approved 6743, Rejected 2581)
SELECT loan_status, COUNT(*) 
FROM loan_applications 
GROUP BY loan_status;

-- Quick look at the actual data
SELECT * FROM loan_applications;

-- Q1: What factors most influence loan approval vs rejection?

--Q1(a): Overall LOAN approval rate
SELECT
    loan_status,
    COUNT(*) AS total,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM loan_applications
GROUP BY loan_status;
--Q1(b):Average credit score, income, DTI ratio by approval status
SELECT
    loan_status,
    ROUND(AVG(credit_score), 0) AS avg_credit_score,
    ROUND(AVG(annual_income), 2) AS avg_income,
    ROUND(AVG(debt_to_income_ratio), 3) AS avg_dti_ratio,
    ROUND(AVG(existing_loans), 1) AS avg_existing_loans
FROM loan_applications
GROUP BY loan_status;

-- Q2: Which segments have the highest rejection rates?

-- Q2(a):Rejection rate by credit score band
SELECT
    credit_score_band,
    COUNT(*) AS total_applications,
    SUM(CASE WHEN loan_status = 'Rejected' THEN 1 ELSE 0 END) AS rejected_count,
    ROUND(100.0 * SUM(CASE WHEN loan_status = 'Rejected' THEN 1 ELSE 0 END) / COUNT(*), 2) AS rejection_rate_pct
FROM loan_applications
GROUP BY credit_score_band
ORDER BY rejection_rate_pct DESC;

-- Q2(b): Rejection rate by income bracket
SELECT
    income_bracket,
    COUNT(*) AS total_applications,
    SUM(CASE WHEN loan_status = 'Rejected' THEN 1 ELSE 0 END) AS rejected_count,
    ROUND(100.0 * SUM(CASE WHEN loan_status = 'Rejected' THEN 1 ELSE 0 END) / COUNT(*), 2) AS rejection_rate_pct
FROM loan_applications
GROUP BY income_bracket
ORDER BY rejection_rate_pct DESC; 

-- Q2(c). Rejection rate by employment type
SELECT
    employment_type,
    COUNT(*) AS total_applications,
    SUM(CASE WHEN loan_status = 'Rejected' THEN 1 ELSE 0 END) AS rejected_count,
    ROUND(100.0 * SUM(CASE WHEN loan_status = 'Rejected' THEN 1 ELSE 0 END) / COUNT(*), 2) AS rejection_rate_pct
FROM loan_applications
GROUP BY employment_type
ORDER BY rejection_rate_pct DESC;

-- Q2(d). Combined ranking: which segment (any dimension) has the single highest
-- rejection rate, using a CTE + RANK() window function
WITH segment_rejection AS (
    SELECT 'Credit Score Band' AS dimension, credit_score_band AS segment,
           COUNT(*) AS total, SUM(CASE WHEN loan_status='Rejected' THEN 1 ELSE 0 END) AS rejected
    FROM loan_applications GROUP BY credit_score_band
    UNION ALL
    SELECT 'Income Bracket', income_bracket,
           COUNT(*), SUM(CASE WHEN loan_status='Rejected' THEN 1 ELSE 0 END)
    FROM loan_applications GROUP BY income_bracket
    UNION ALL
    SELECT 'Employment Type', employment_type,
           COUNT(*), SUM(CASE WHEN loan_status='Rejected' THEN 1 ELSE 0 END)
    FROM loan_applications GROUP BY employment_type
)
SELECT
    dimension,
    segment,
    total,
    rejected,
    ROUND(100.0 * rejected / total, 2) AS rejection_rate_pct,
    RANK() OVER (ORDER BY (100.0 * rejected / total) DESC) AS risk_rank
FROM segment_rejection
ORDER BY risk_rank
LIMIT 10;

-- Q3: How does loan purpose affect approval likelihood?
SELECT
    loan_purpose,
    COUNT(*) AS total_applications,
    SUM(CASE WHEN loan_status = 'Approved' THEN 1 ELSE 0 END) AS approved_count,
    ROUND(100.0 * SUM(CASE WHEN loan_status = 'Approved' THEN 1 ELSE 0 END) / COUNT(*), 2) AS approval_rate_pct,
    ROUND(AVG(loan_amount), 2) AS avg_loan_amount
FROM loan_applications
GROUP BY loan_purpose
ORDER BY approval_rate_pct DESC;

-- Q4: Do demographic factors show meaningful patterns in approval?

-- Q4(a). By age group
SELECT
    CASE
        WHEN age < 25 THEN 'Under 25'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        WHEN age BETWEEN 45 AND 54 THEN '45-54'
        WHEN age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END AS age_group,
    COUNT(*) AS total_applications,
    ROUND(100.0 * SUM(CASE WHEN loan_status = 'Approved' THEN 1 ELSE 0 END) / COUNT(*), 2) AS approval_rate_pct
FROM loan_applications
GROUP BY age_group
ORDER BY age_group;

-- Q4(b). By education level
SELECT
    education_level,
    COUNT(*) AS total_applications,
    ROUND(100.0 * SUM(CASE WHEN loan_status = 'Approved' THEN 1 ELSE 0 END) / COUNT(*), 2) AS approval_rate_pct
FROM loan_applications
GROUP BY education_level
ORDER BY approval_rate_pct DESC;
 
-- Q4(c). By marital status
SELECT
    marital_status,
    COUNT(*) AS total_applications,
    ROUND(100.0 * SUM(CASE WHEN loan_status = 'Approved' THEN 1 ELSE 0 END) / COUNT(*), 2) AS approval_rate_pct
FROM loan_applications
GROUP BY marital_status
ORDER BY approval_rate_pct DESC;

-- Q5: Relationship between loan amount / interest rate and approval
SELECT
    loan_status,
    ROUND(AVG(loan_amount), 2) AS avg_loan_amount,
    ROUND(MIN(loan_amount), 2) AS min_loan_amount,
    ROUND(MAX(loan_amount), 2) AS max_loan_amount,
    ROUND(AVG(interest_rate), 2) AS avg_interest_rate,
    ROUND(AVG(loan_term_months), 0) AS avg_term_months
FROM loan_applications
GROUP BY loan_status;


-- Q6: Trend in applications / approval rate over time


-- Q6(a). Applications and approval rate by year
SELECT
    application_year,
    COUNT(*) AS total_applications,
    SUM(CASE WHEN loan_status = 'Approved' THEN 1 ELSE 0 END) AS approved_count,
    ROUND(100.0 * SUM(CASE WHEN loan_status = 'Approved' THEN 1 ELSE 0 END) / COUNT(*), 2) AS approval_rate_pct
FROM loan_applications
WHERE application_year IS NOT NULL
GROUP BY application_year
ORDER BY application_year;


-- Q6(b). Month-over-month trend with LAG() window function for growth rate
WITH monthly_apps AS (
    SELECT
        application_year,
        application_month,
        COUNT(*) AS total_applications
    FROM loan_applications
    WHERE application_year IS NOT NULL AND application_month IS NOT NULL
    GROUP BY application_year, application_month
)
SELECT
    application_year,
    application_month,
    total_applications,
    LAG(total_applications) OVER (ORDER BY application_year, application_month) AS prev_month_applications,
    ROUND(
        100.0 * (total_applications - LAG(total_applications) OVER (ORDER BY application_year, application_month))
        / NULLIF(LAG(total_applications) OVER (ORDER BY application_year, application_month), 0), 2
    ) AS mom_growth_pct
FROM monthly_apps
ORDER BY application_year, application_month;
 
-- BONUS: Overall risk-scoring style query (RANK + NTILE)
-- Useful for a dedicated "Risk Segments" Power BI page


SELECT
    customer_id,
    credit_score,
    annual_income,
    debt_to_income_ratio,
    loan_status,
    NTILE(4) OVER (ORDER BY credit_score) AS credit_score_quartile
FROM loan_applications
LIMIT 20;

