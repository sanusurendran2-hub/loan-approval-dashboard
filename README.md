# Loan Approval Analytics Dashboard

An end-to-end data analytics project analyzing loan approval patterns using a raw, synthetic bank loan dataset — covering data cleaning, SQL-based business analysis, and an interactive Streamlit dashboard.

🔗 **Live Dashboard:** [https://loanapproval-sanu.streamlit.app](https://loanapproval-sanu.streamlit.app)

---

## Project Overview

This project investigates what factors influence loan approval vs. rejection decisions, using a raw dataset with realistic data quality issues (missing values, 200 features including anonymized/noise columns). The goal was to simulate a real-world analytics workflow: from messy raw data to a decision-ready dashboard.

**Business questions explored:**
1. What factors most influence loan approval vs. rejection?
2. Which applicant segments have the highest rejection rates?
3. How does loan purpose affect approval likelihood?
4. Do demographic factors (age, education, marital status) show patterns in approval?
5. What's the relationship between loan amount/interest rate and approval outcome?
6. Are there trends in applications or approval rate over time?

---

## Project Structure

```
├── app.py                                    # Streamlit dashboard
├── requirements.txt                          # Python dependencies
├── loan_data.csv                             # Cleaned dataset used by the dashboard
├── python/
│   └── loan_approval_analysis.ipynb          # Data profiling & cleaning (Google Colab)
├── sql/
│   └── 03_business_queries.sql               # Table schema + business-question SQL queries
└── README.md
```

---

## Workflow

**1. Data Profiling & Cleaning (Python / Google Colab)**
- Source: raw synthetic bank loan dataset (10,000 rows × 200 columns)
- Identified 18 business-relevant columns out of 200 (remainder were anonymized/noise features)
- Profiled missing values (~7% uniformly missing across key columns)
- Dropped rows with missing target variable (`loan_status`)
- Imputed numeric columns with median, categorical columns marked as "Unknown" to preserve transparency about missingness
- Created derived features: `income_bracket`, `credit_score_band`
- Final cleaned dataset: 9,324 rows × 20 columns

**2. SQL Analysis (PostgreSQL / pgAdmin4)**
- Loaded cleaned data into a PostgreSQL database
- Wrote business-question queries using CTEs and window functions (`RANK()`, `LAG()`, `NTILE()`)
- Analyzed approval/rejection patterns across credit score bands, income brackets, employment type, loan purpose, and demographics
- Built a month-over-month application trend using `LAG()` for growth rate calculation

**3. Dashboard (Streamlit)**
- Interactive dashboard with year and loan-status filters
- KPI summary: total applications, approval rate, average loan amount, average interest rate
- Segmented visualizations: approval/rejection by credit score band, loan purpose, and demographic factors
- Trend view of applications over time

---

## Key Findings

- Overall approval rate: **72.3%** (6,743 Approved / 2,581 Rejected)
- Traditional risk factors (credit score, income) showed only a weak relationship with approval outcome in this dataset — approval rates stayed fairly consistent (27-30%) across credit score bands and income brackets
- Applications with missing/incomplete employment information had the highest rejection rate (30.1%), suggesting incomplete applications are a stronger predictor of rejection than the applicant's financial profile itself

---

## Tools Used

- **Python** (pandas, numpy) — data profiling and cleaning
- **Google Colab** — cleaning environment
- **PostgreSQL / pgAdmin4** — database and SQL analysis
- **Streamlit** — interactive dashboard
- **GitHub** — version control and portfolio hosting

---

## Dataset

Raw synthetic bank loan dataset sourced from Kaggle (intentionally includes missing values and mixed data types to simulate real-world data quality challenges).
