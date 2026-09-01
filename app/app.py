import streamlit as st
import pandas as pd
import numpy as np
import plotly.express as px
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
# ============================================================
# PAGE CONFIGURATION
# ============================================================

st.set_page_config(
    page_title="Supply Chain Operations Intelligence",
    page_icon="🚚",
    layout="wide"
)


# # ============================================================
# # DATABASE CONNECTION
# # ============================================================

# @st.cache_resource
# def get_engine():

#     server = r"SAM\SQLEXPRESS"
#     database = "SupplyChainAnalytics"
#     driver = "ODBC Driver 17 for SQL Server"

#     connection_string = (
#         f"mssql+pyodbc://@{server}/{database}"
#         f"?driver={driver.replace(' ', '+')}"
#         "&trusted_connection=yes"
#     )

#     return create_engine(connection_string)


# ============================================================
# LOAD ORDER ANALYTICS
# ============================================================

@st.cache_data
def load_order_analytics():

    path = BASE_DIR / "data" / "order_analytics.csv"

    return pd.read_csv(path)


# ============================================================
# LOAD INTERVENTION DATA
# ============================================================

@st.cache_data
def load_intervention_data():

    path = (
        BASE_DIR
        / "data"
        / "intervention_priority_output.csv"
    )

    return pd.read_csv(path)


# ============================================================
# LOAD DATA
# ============================================================

try:

    orders = load_order_analytics()
    interventions = load_intervention_data()

except Exception as e:

    st.error("Unable to load project data.")

    st.code(str(e))

    st.stop()


# ============================================================
# DATA PREPARATION
# ============================================================

# Convert timestamps where available

date_columns = [
    "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_carrier_date",
    "order_delivered_customer_date",
    "order_estimated_delivery_date"
]

for col in date_columns:

    if col in orders.columns:

        orders[col] = pd.to_datetime(
            orders[col],
            errors="coerce"
        )


# ============================================================
# SIDEBAR
# ============================================================

st.sidebar.title("🚚 Supply Chain Intelligence")

st.sidebar.markdown(
    """
    **Supply Chain & Delivery Operations Intelligence**

    Root-Cause Analysis → Risk Prediction → Intervention Optimization
    """
)

page = st.sidebar.radio(
    "Navigate",
    [
        "Executive Overview",
        "Delivery & Root Cause",
        "Risk & Prediction",
        "Intervention Simulator"
    ]
)


# ============================================================
# TITLE
# ============================================================

st.title("Supply Chain & Delivery Operations Intelligence")

st.caption(
    "Operational analytics, delivery risk prediction and intervention prioritization"
)


# ============================================================
# PAGE 1 — EXECUTIVE OVERVIEW
# ============================================================

if page == "Executive Overview":

    st.header("📊 Executive Overview")

    # --------------------------------------------------------
    # KPIs
    # --------------------------------------------------------

    total_orders = len(orders)

    late_orders = (
        orders["is_late"].sum()
        if "is_late" in orders.columns
        else np.nan
    )

    late_rate = (
        late_orders / total_orders * 100
        if total_orders > 0
        else np.nan
    )

    avg_order_value = (
        orders["total_order_value"].mean()
        if "total_order_value" in orders.columns
        else np.nan
    )

    avg_freight = (
        orders["freight_value"].mean()
        if "freight_value" in orders.columns
        else np.nan
    )

    col1, col2, col3, col4, col5 = st.columns(5)

    col1.metric(
        "Total Orders",
        f"{total_orders:,}"
    )

    col2.metric(
        "Late Orders",
        f"{int(late_orders):,}"
    )

    col3.metric(
        "Late Delivery Rate",
        f"{late_rate:.2f}%"
    )

    col4.metric(
        "Avg Order Value",
        f"{avg_order_value:,.2f}"
    )

    col5.metric(
        "Avg Freight",
        f"{avg_freight:,.2f}"
    )

    st.divider()

    # --------------------------------------------------------
    # ORDER STATUS
    # --------------------------------------------------------

    col1, col2 = st.columns(2)

    if "order_status" in orders.columns:

        status_df = (
            orders["order_status"]
            .value_counts()
            .reset_index()
        )

        status_df.columns = [
            "order_status",
            "count"
        ]

        fig = px.bar(
            status_df,
            x="order_status",
            y="count",
            title="Orders by Status"
        )

        col1.plotly_chart(
            fig,
            use_container_width=True
        )

    # --------------------------------------------------------
    # STATE PERFORMANCE
    # --------------------------------------------------------

    if (
        "customer_state" in orders.columns
        and "is_late" in orders.columns
    ):

        state_df = (
            orders
            .groupby("customer_state")
            .agg(
                orders=("order_id", "count"),
                late_rate=("is_late", "mean")
            )
            .reset_index()
        )

        state_df["late_rate"] *= 100

        state_df = state_df.sort_values(
            "late_rate",
            ascending=False
        )

        fig = px.bar(
            state_df.head(15),
            x="customer_state",
            y="late_rate",
            title="Top States by Late Delivery Rate"
        )

        col2.plotly_chart(
            fig,
            use_container_width=True
        )


# ============================================================
# PAGE 2 — DELIVERY & ROOT CAUSE
# ============================================================

elif page == "Delivery & Root Cause":

    st.header("🚚 Delivery Performance & Root Cause")

    # --------------------------------------------------------
    # DELIVERY METRICS
    # --------------------------------------------------------

    col1, col2, col3 = st.columns(3)

    if "fulfillment_days" in orders.columns:

        col1.metric(
            "Avg Fulfillment Time",
            f"{orders['fulfillment_days'].mean():.2f} days"
        )

    if "delay_days" in orders.columns:

        col2.metric(
            "Avg Delay",
            f"{orders['delay_days'].mean():.2f} days"
        )

    if "is_late" in orders.columns:

        col3.metric(
            "Late Orders",
            f"{int(orders['is_late'].sum()):,}"
        )

    st.divider()

    # --------------------------------------------------------
    # DELAY DISTRIBUTION
    # --------------------------------------------------------

    if "delay_days" in orders.columns:

        fig = px.histogram(
            orders,
            x="delay_days",
            nbins=50,
            title="Delivery Delay Distribution"
        )

        st.plotly_chart(
            fig,
            use_container_width=True
        )

    # --------------------------------------------------------
    # STATE LATE RATE
    # --------------------------------------------------------

    if (
        "customer_state" in orders.columns
        and "is_late" in orders.columns
    ):

        state_df = (
            orders
            .groupby("customer_state")
            .agg(
                orders=("order_id", "count"),
                late_orders=("is_late", "sum")
            )
            .reset_index()
        )

        state_df["late_rate"] = (
            state_df["late_orders"]
            / state_df["orders"]
            * 100
        )

        fig = px.bar(
            state_df.sort_values(
                "late_rate",
                ascending=False
            ),
            x="customer_state",
            y="late_rate",
            title="Late Delivery Rate by State"
        )

        st.plotly_chart(
            fig,
            use_container_width=True
        )

    # --------------------------------------------------------
    # KEY INTERPRETATION
    # --------------------------------------------------------

    st.info(
        """
        **Business interpretation:**

        Delivery failures should be investigated across the
        fulfillment pipeline — processing, shipping and final-mile
        delivery — rather than treating late delivery as a single
        isolated problem.
        """
    )


# ============================================================
# PAGE 3 — RISK & PREDICTION
# ============================================================

elif page == "Risk & Prediction":

    st.header("⚠️ Delivery Risk & Prediction")

    # --------------------------------------------------------
    # RISK KPIs
    # --------------------------------------------------------

    if "risk_score" in interventions.columns:

        high_risk = (
            interventions["risk_score"] >=
            interventions["risk_score"].quantile(0.90)
        ).sum()

        avg_risk = (
            interventions["risk_score"].mean()
        )

    else:

        high_risk = 0
        avg_risk = 0

    if "late_probability" in interventions.columns:

        avg_probability = (
            interventions["late_probability"].mean()
        )

    else:

        avg_probability = 0

    col1, col2, col3 = st.columns(3)

    col1.metric(
        "High-Risk Orders",
        f"{high_risk:,}"
    )

    col2.metric(
        "Average Risk Score",
        f"{avg_risk:.2f}"
    )

    col3.metric(
        "Average Late Probability",
        f"{avg_probability:.2%}"
    )

    st.divider()

    # --------------------------------------------------------
    # RISK BAND
    # --------------------------------------------------------

    if "risk_band" in interventions.columns:

        risk_df = (
            interventions["risk_band"]
            .value_counts()
            .reset_index()
        )

        risk_df.columns = [
            "risk_band",
            "count"
        ]

        fig = px.pie(
            risk_df,
            names="risk_band",
            values="count",
            title="Risk Band Distribution"
        )

        st.plotly_chart(
            fig,
            use_container_width=True
        )

    # --------------------------------------------------------
    # RISK VS IMPACT
    # --------------------------------------------------------

    if {
        "risk_score",
        "impact_score"
    }.issubset(interventions.columns):

        fig = px.scatter(
            interventions.sample(
                min(10000, len(interventions)),
                random_state=42
            ),
            x="risk_score",
            y="impact_score",
            title="Risk vs Business Impact",
            hover_data=[
                "order_id"
            ]
        )

        st.plotly_chart(
            fig,
            use_container_width=True
        )


# ============================================================
# PAGE 4 — INTERVENTION SIMULATOR
# ============================================================

elif page == "Intervention Simulator":

    st.header("🎯 Intervention Simulator")

    st.markdown(
        """
        Use this module to identify which orders should receive
        operational intervention when intervention capacity is limited.
        """
    )

    # --------------------------------------------------------
    # CAPACITY CONTROL
    # --------------------------------------------------------

    capacity = st.slider(
        "Intervention Capacity",
        min_value=100,
        max_value=1000,
        value=500,
        step=100
    )

    # --------------------------------------------------------
    # RANK ORDERS
    # --------------------------------------------------------

    required_columns = {
        "priority_score",
        "order_id"
    }

    if required_columns.issubset(
        interventions.columns
    ):

        selected = (
            interventions
            .sort_values(
                "priority_score",
                ascending=False
            )
            .head(capacity)
            .copy()
        )

        # ----------------------------------------------------
        # KPIs
        # ----------------------------------------------------

        selected_late = (
            selected["is_late"].sum()
            if "is_late" in selected.columns
            else 0
        )

        selected_value = (
            selected["total_order_value"].sum()
            if "total_order_value"
            in selected.columns
            else 0
        )

        avg_risk = (
            selected["risk_score"].mean()
            if "risk_score" in selected.columns
            else 0
        )

        avg_impact = (
            selected["impact_score"].mean()
            if "impact_score" in selected.columns
            else 0
        )

        col1, col2, col3, col4 = st.columns(4)

        col1.metric(
            "Selected Orders",
            f"{len(selected):,}"
        )

        col2.metric(
            "Late Orders",
            f"{int(selected_late):,}"
        )

        col3.metric(
            "Average Risk",
            f"{avg_risk:.2f}"
        )

        col4.metric(
            "Average Impact",
            f"{avg_impact:,.2f}"
        )

        st.divider()

        # ----------------------------------------------------
        # STATE CONCENTRATION
        # ----------------------------------------------------

        if "customer_state" in selected.columns:

            state_df = (
                selected["customer_state"]
                .value_counts()
                .reset_index()
            )

            state_df.columns = [
                "customer_state",
                "interventions"
            ]

            fig = px.bar(
                state_df.head(15),
                x="customer_state",
                y="interventions",
                title="Intervention Concentration by State"
            )

            st.plotly_chart(
                fig,
                use_container_width=True
            )

        # ----------------------------------------------------
        # INTERVENTION TABLE
        # ----------------------------------------------------

        display_columns = [
            "order_id",
            "customer_state",
            "late_probability",
            "risk_score",
            "impact_score",
            "priority_score",
            "intervention_tier",
            "recommended_action"
        ]

        display_columns = [
            c for c in display_columns
            if c in selected.columns
        ]

        st.subheader(
            "Recommended Intervention Orders"
        )

        st.dataframe(
            selected[display_columns],
            use_container_width=True,
            hide_index=True
        )

        # ----------------------------------------------------
        # DOWNLOAD
        # ----------------------------------------------------

        csv = selected.to_csv(
            index=False
        ).encode("utf-8")

        st.download_button(
            label="⬇️ Download Intervention List",
            data=csv,
            file_name="optimized_interventions.csv",
            mime="text/csv"
        )

    else:

        st.error(
            "Required intervention columns are missing."
        )