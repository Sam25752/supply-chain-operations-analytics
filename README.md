# Supply Chain & Delivery Operations Intelligence

### Root-Cause Analysis, Late-Delivery Risk & Intervention Prioritization

🔗 **Live Dashboard:** [Open Streamlit Dashboard](https://supply-chain-operations-analytics-fn2aqitymk8u2wcd4haswz.streamlit.app/)

🔗 **GitHub Repository:** [View Source Code](https://github.com/Sam25752/supply-chain-operations-analytics)

---

## 📌 Project Overview

Delivery delays are not simply a customer-service problem. They can originate from
multiple operational factors including fulfillment time, shipping performance,
seller behavior, geographic concentration, freight economics, and order
characteristics.

This project builds an end-to-end **Supply Chain & Delivery Operations Intelligence
system** to answer:

> **Where are delivery and fulfillment problems coming from, what factors are
> driving SLA failures and operational costs, and where should the company
> prioritize interventions?**

The project combines:

- SQL-based operational analytics
- Exploratory Data Analysis
- Delivery performance analysis
- Root-cause analysis
- Statistical analysis
- Late-delivery prediction
- Risk scoring
- Intervention prioritization
- Capacity-constrained optimization
- Streamlit decision-support dashboard

---

# 🎯 Business Problem

A logistics/e-commerce organization needs to determine:

1. Which orders are most likely to experience delivery delays?
2. What operational factors contribute to late delivery?
3. Which geographic regions show higher operational risk?
4. How concentrated is intervention exposure across sellers and states?
5. Which orders should operations teams prioritize when intervention capacity
   is limited?
6. How can interventions be allocated while controlling concentration risk?

The goal is therefore not merely to **predict delays**, but to convert prediction
into an **actionable intervention strategy**.

---

# 📊 Dataset

The project uses the **Olist Brazilian E-Commerce dataset**, containing
approximately 100K orders and multiple relational tables covering:

- Orders
- Customers
- Order items
- Products
- Sellers
- Payments
- Reviews
- Geographic information

The data contains order timestamps, estimated delivery dates, actual delivery
events, product/order characteristics, freight values, customer locations and
seller information.

---

# 🏗️ Project Architecture

```text
Raw Olist Data
      │
      ▼
Data Quality & Validation
      │
      ▼
SQL Relational Analytics
      │
      ├───────────────┐
      ▼               ▼
Order Metrics     Delivery Metrics
      │               │
      └───────┬───────┘
              ▼
       Order-Level Analytics
              │
              ▼
      Python Exploratory Analysis
              │
              ▼
       Statistical Analysis
              │
              ▼
     Late-Delivery Prediction
              │
              ▼
          Risk Scoring
              │
              ▼
   Intervention Prioritization
              │
              ▼
 Capacity-Constrained Optimization
              │
              ▼
       Streamlit Decision Tool


🔍 Analytical Workflow
1. Data Quality & Validation

Before analysis, the raw relational data was validated for:

Duplicate order IDs
Duplicate customer/seller identifiers
Identifier formatting problems
Missing relationships
Referential integrity
Order-level grain
Payment consistency
Order-item consistency
Timestamp validity
Invalid processing/shipping durations

The analytical dataset was validated at one row per order.

2. SQL Analytics

SQL was used to construct operational metrics using:

Multi-table joins
Aggregations
CTEs
Window functions
ROW_NUMBER
RANK
DENSE_RANK
LAG
LEAD
Windowed SUM
Windowed AVG

Key analytical layers include:

Order metrics
Delivery metrics
Seller performance
Geographic analysis
Root-cause analysis
Order-level analytical view

🚚 Delivery Performance

The delivery analysis classified orders into:

Category	   Orders
Early	       88,644
Late	        7,826
Not Delivered	2,971

Overall late-delivery rate among the analyzed order population was approximately: 8.11%

The analysis also examined:

Fulfillment time
Delivery delay
Processing time
Shipping time
SLA performance
Delay severity


🧠 Root-Cause Analysis

The project investigates potential operational drivers of delivery
performance across dimensions such as:

Operational
Processing duration
Shipping duration
Fulfillment duration
Order complexity
Geographic
Customer state
Regional concentration
State-level late-delivery performance
Seller
Seller intervention exposure
Seller concentration
Operational risk concentration
Economic
Order value
Freight value
Potential financial impact of operational failures


🤖 Late-Delivery Risk Modeling

A machine-learning component estimates the probability that an order will
experience a late delivery.

The model output is converted into an operational:

risk_score

and:

risk_band

This allows operations teams to move from:

"Which orders are already late?"

to:

"Which orders are at higher risk and should receive attention?"

🎯 Intervention Prioritization

Prediction alone does not determine which orders should be acted upon.

The project therefore combines:

Late-delivery probability
Risk score
Economic impact
Order characteristics
Operational exposure

to generate:

impact_score
priority_score

and:

intervention_tier

Orders are classified into intervention categories such as:

Critical
High Priority
Standard Intervention
⚙️ Capacity-Constrained Optimization

A realistic operations team has limited intervention capacity.

The project therefore simulates a fixed intervention capacity of:

500 orders

Rather than simply selecting the 500 highest-risk orders, the optimization
framework considers operational concentration.

Constraints include:

Intervention capacity
Seller exposure
Geographic concentration
Order-level uniqueness

The optimization successfully returned:

Solver Status: Optimal
Selected Orders: 500
Distinct Orders: 500

This converts the project from a simple predictive model into a:

Decision-support and intervention allocation framework.

📈 Key Results
Delivery Performance
99,441 total orders analyzed
7,826 late orders
8.11% late-delivery rate
2,971 orders not delivered in the available delivery data
Intervention Optimization
98,666 optimization candidates
500 intervention capacity
500 optimized orders selected
193 sellers represented among selected interventions
Maximum baseline seller exposure: 35 orders
Top-state concentration: 28.8%
Economic Impact

For the final optimization candidate population:

Average impact score: approximately 160.58
Average impact score among the top 500 baseline candidates:
approximately 2,107.81

The optimized intervention framework therefore focuses operational resources
on orders with substantially higher estimated impact than the average candidate.

🖥️ Streamlit Decision-Support Application

The project includes an interactive Streamlit application providing
operational decision support.

Dashboard sections include:
1. Executive Overview

Provides a high-level view of:

Order volume
Delivery performance
Late-order metrics
Geographic performance
Operational KPIs
2. Delivery & Root Cause

Explores:

Delivery delays
Fulfillment performance
Geographic differences
Operational drivers
3. Risk & Prediction

Provides:

Late-delivery probability
Risk scores
Risk bands
Risk/impact analysis
4. Intervention Simulator

Allows users to explore:

Intervention capacity
Priority orders
Intervention tiers
Recommended operational actions


🛠️ Technology Stack
| Area             | Technologies                         |
| ---------------- | ------------------------------------ |
| Database         | Microsoft SQL Server                 |
| SQL              | Advanced SQL, CTEs, Window Functions |
| Analysis         | Python, Pandas, NumPy                |
| Statistics       | SciPy, Statsmodels                   |
| Machine Learning | Scikit-learn                         |
| Visualization    | Plotly                               |
| Optimization     | Python Optimization                  |
| Dashboard        | Streamlit                            |
| Version Control  | Git & GitHub                         |



📁 Project Structure

supply-chain-operations-analytics/
│
├── app/
│   └── app.py
│
├── data/
│   ├── order_analytics.csv
│   └── intervention_priority_output.csv
│
├── docs/
│   ├── data_inventory.md
│   └── data_dictionary.md
│
├── sql/
│   ├── 00_create_database.sql
│   ├── 01_create_raw_tables.sql
│   ├── 02_load_raw_data.sql
│   ├── 03_data_quality.sql
│   ├── 04_order_metrics.sql
│   ├── 05_delivery_metrics.sql
│   ├── 06_seller_performance.sql
│   ├── 07_geographic_analysis.sql
│   └── 08_root_cause_analysis.sql
│
├── notebooks/
│   ├── 01_eda.ipynb
│   ├── 02_delivery_analysis.ipynb
│   ├── 03_statistical_analysis.ipynb
│   ├── 04_delay_prediction.ipynb
│   └── 05_intervention_prioritization.ipynb
│
├── src/
├── README.md
└── requirements.txt


🚀 Business Impact

The framework demonstrates how operational analytics can progress through
the complete decision pipeline:
Descriptive Analytics
        ↓
Diagnostic Analytics
        ↓
Predictive Analytics
        ↓
Prescriptive Analytics

👩‍💻 Author

Samiksha Agarwal

B.Tech — Electrical Engineering

Interested in Data Analytics, Operations Analytics, Business Analytics,
Product Analytics and Decision Science.