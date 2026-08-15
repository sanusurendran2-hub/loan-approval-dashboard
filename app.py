import streamlit as st
import pandas as pd
import plotly.express as px

# ---------- Page config ----------
st.set_page_config(
    page_title="Loan Approval Dashboard",
    page_icon="💰",
    layout="wide"
)

# ---------- Load data ----------
@st.cache_data
def load_data():
    df = pd.read_csv("loan_data.csv")
    df["application_date"] = pd.to_datetime(df["application_date"], errors="coerce")
    return df

df = load_data()

# ---------- Sidebar filters ----------
st.sidebar.header("Filters")

status_options = st.sidebar.multiselect(
    "Loan Status",
    options=sorted(df["loan_status"].unique()),
    default=sorted(df["loan_status"].unique())
)

employment_options = st.sidebar.multiselect(
    "Employment Type",
    options=sorted(df["employment_type"].unique()),
    default=sorted(df["employment_type"].unique())
)

education_options = st.sidebar.multiselect(
    "Education Level",
    options=sorted(df["education_level"].unique()),
    default=sorted(df["education_level"].unique())
)

min_credit, max_credit = int(df["credit_score"].min()), int(df["credit_score"].max())
credit_range = st.sidebar.slider(
    "Credit Score Range",
    min_value=min_credit,
    max_value=max_credit,
    value=(min_credit, max_credit)
)

purpose_options = st.sidebar.multiselect(
    "Loan Purpose",
    options=sorted(df["loan_purpose"].unique()),
    default=sorted(df["loan_purpose"].unique())
)

ownership_options = st.sidebar.multiselect(
    "Home Ownership",
    options=sorted(df["home_ownership"].unique()),
    default=sorted(df["home_ownership"].unique())
)

income_bracket_options = st.sidebar.multiselect(
    "Income Bracket",
    options=sorted(df["income_bracket"].unique()),
    default=sorted(df["income_bracket"].unique())
)

years_available = sorted(df["application_year"].dropna().unique().astype(int))
year_options = st.sidebar.multiselect(
    "Application Year",
    options=years_available,
    default=years_available
)

# ---------- Apply filters ----------
filtered_df = df[
    (df["loan_status"].isin(status_options)) &
    (df["employment_type"].isin(employment_options)) &
    (df["education_level"].isin(education_options)) &
    (df["credit_score"].between(credit_range[0], credit_range[1])) &
    (df["loan_purpose"].isin(purpose_options)) &
    (df["home_ownership"].isin(ownership_options)) &
    (df["income_bracket"].isin(income_bracket_options)) &
    (df["application_year"].isin(year_options) | df["application_year"].isna())
]

# ---------- Title ----------
st.title("💰 Loan Approval Analytics Dashboard")
st.markdown("Interactive analysis of loan applications, approval trends, and risk factors.")

# ---------- KPI Cards ----------
total_apps = len(filtered_df)
approval_rate = (filtered_df["loan_status"] == "Approved").mean() * 100 if total_apps > 0 else 0
avg_loan_amount = filtered_df["loan_amount"].mean() if total_apps > 0 else 0
avg_credit_score = filtered_df["credit_score"].mean() if total_apps > 0 else 0

col1, col2, col3, col4 = st.columns(4)
col1.metric("Total Applications", f"{total_apps:,}")
col2.metric("Approval Rate", f"{approval_rate:.1f}%")
col3.metric("Avg Loan Amount", f"₹{avg_loan_amount:,.0f}")
col4.metric("Avg Credit Score", f"{avg_credit_score:.0f}")

st.markdown("---")

# ---------- Row 1: Approval rate by credit band & income bracket ----------
row1_col1, row1_col2 = st.columns(2)

with row1_col1:
    st.subheader("Approval Rate by Credit Score Band")
    credit_band_order = ["Poor", "Fair", "Good", "Very Good", "Excellent"]
    band_summary = (
        filtered_df.groupby("credit_score_band")["loan_status"]
        .apply(lambda x: (x == "Approved").mean() * 100)
        .reindex([b for b in credit_band_order if b in filtered_df["credit_score_band"].unique()])
        .reset_index(name="approval_rate")
    )
    fig1 = px.bar(
        band_summary, x="credit_score_band", y="approval_rate",
        labels={"credit_score_band": "Credit Score Band", "approval_rate": "Approval Rate (%)"},
        text_auto=".1f"
    )
    fig1.update_traces(marker_color="#2E86AB")
    st.plotly_chart(fig1, use_container_width=True)

with row1_col2:
    st.subheader("Approval Rate by Income Bracket")
    income_order = ["Low (<20K)", "Lower-Mid (20-40K)", "Upper-Mid (40-60K)", "High (60K+)"]
    income_summary = (
        filtered_df.groupby("income_bracket")["loan_status"]
        .apply(lambda x: (x == "Approved").mean() * 100)
        .reindex([b for b in income_order if b in filtered_df["income_bracket"].unique()])
        .reset_index(name="approval_rate")
    )
    fig2 = px.bar(
        income_summary, y="income_bracket", x="approval_rate",
        orientation="h",
        labels={"income_bracket": "Income Bracket", "approval_rate": "Approval Rate (%)"},
        text_auto=".1f"
    )
    fig2.update_traces(marker_color="#588157")
    fig2.update_layout(yaxis={"categoryorder": "array", "categoryarray": income_order[::-1]})
    st.plotly_chart(fig2, use_container_width=True)

# ---------- Row 2: Loan amount distribution & loan purpose ----------
row2_col1, row2_col2 = st.columns(2)

with row2_col1:
    st.subheader("Loan Amount Distribution")
    fig3 = px.histogram(
        filtered_df, x="loan_amount", color="loan_status",
        nbins=40, barmode="overlay", opacity=0.7,
        labels={"loan_amount": "Loan Amount (₹)"},
        color_discrete_map={"Approved": "#588157", "Rejected": "#BC4749"}
    )
    st.plotly_chart(fig3, use_container_width=True)

with row2_col2:
    st.subheader("Applications by Loan Purpose")
    purpose_counts = filtered_df["loan_purpose"].value_counts().reset_index()
    purpose_counts.columns = ["loan_purpose", "count"]
    fig4 = px.pie(
        purpose_counts, names="loan_purpose", values="count", hole=0.4,
        color_discrete_sequence=px.colors.qualitative.Set2
    )
    st.plotly_chart(fig4, use_container_width=True)

# ---------- Row 3: Applications over time ----------
st.subheader("Applications Over Time")
time_df = filtered_df.dropna(subset=["application_year", "application_month"]).copy()
if len(time_df) > 0:
    time_df["year_month"] = pd.to_datetime(
        time_df["application_year"].astype(int).astype(str) + "-" +
        time_df["application_month"].astype(int).astype(str) + "-01"
    )
    trend = time_df.groupby("year_month").size().reset_index(name="applications")
    fig5 = px.line(trend, x="year_month", y="applications", markers=True)
    st.plotly_chart(fig5, use_container_width=True)
else:
    st.info("No date data available for the current filter selection.")

# ---------- Row 4: Debt-to-income vs loan status ----------
st.subheader("Debt-to-Income Ratio by Loan Status")
fig6 = px.box(
    filtered_df, x="loan_status", y="debt_to_income_ratio", color="loan_status"
)
st.plotly_chart(fig6, use_container_width=True)

# ---------- Raw data ----------
with st.expander("View Filtered Data"):
    st.dataframe(filtered_df)
    st.caption(f"Showing {len(filtered_df):,} of {len(df):,} total records")
