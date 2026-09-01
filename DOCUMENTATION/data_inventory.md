# Olist Data Dictionary

## 1. customers

Grain: customer_id
Primary Key:
Foreign Keys:
Business Purpose:
Important Columns:
Potential Issues:

## 2. orders

Grain: order_id
Primary Key:
Foreign Keys:
Business Purpose:
Important Columns:
Potential Issues:

## 3. order_items

Grain:
Primary Key:
Foreign Keys:
Business Purpose:
Important Columns:
Potential Issues:

## 4. products

Grain: product_id
Primary Key:
Foreign Keys:
Business Purpose:
Important Columns:
Potential Issues:

## 5. sellers

Grain:
Primary Key:
Foreign Keys:
Business Purpose:
Important Columns:
Potential Issues:

## 6. payments

Grain:
Primary Key:
Foreign Keys:
Business Purpose:
Important Columns:
Potential Issues:

## 7. reviews

Grain:
Primary Key:
Foreign Keys:
Business Purpose:
Important Columns:
Potential Issues:

## 8. geolocation

Grain:
Primary Key:
Foreign Keys:
Business Purpose:
Important Columns:
Potential Issues:

## 9. category_translation

Grain:
Primary Key:
Foreign Keys:
Business Purpose:
Important Columns:
Potential Issues:



| Raw table            |      Rows |
| -------------------- | --------: |
| `raw_customers`      |    99,441 |
| `raw_geolocation`    | 1,000,163 |
| `raw_order_items`    |   112,650 |
| `raw_order_payments` |   103,886 |
| `raw_order_reviews`  |    99,224 |
| `raw_orders`         |    99,441 |
| `raw_products`       |    32,951 |
| `raw_sellers`        |     3,095 |




supply-chain-operations-analytics/
│
├── data/
│   └── raw/
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
├── app/
├── README.md
└── requirements.txt
