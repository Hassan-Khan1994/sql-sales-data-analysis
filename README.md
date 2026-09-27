# 🗄️ SQL Sales Data Analysis

An end-to-end **SQL data analysis** project on a relational retail database — schema design, seed data, and **12 analytical queries** (JOINs, aggregations, CTEs, and window functions) that turn transactions into business insight.

> **Author:** Hassan Khan · BI / Data Analyst
> **Tech:** SQL (SQLite-compatible; runs on PostgreSQL/MySQL with minor date-function tweaks)

---

## 🗃️ Database Schema

A normalized 4-table relational model:

```
customers ──< orders ──< order_items >── products
```

| Table | Rows | Key columns |
|-------|------|-------------|
| `customers` | 50 | customer_id, segment, region, city, join_date |
| `products` | 38 | product_id, category, subcategory, unit_price |
| `orders` | 300 | order_id, customer_id, order_date, order_status |
| `order_items` | 741 | order_item_id, order_id, product_id, quantity, discount, sales, profit |

See [`schema.sql`](schema.sql) for full DDL (primary keys, foreign keys, indexes).

---

## 🚀 How to Run

Using **SQLite** (no install beyond the `sqlite3` CLI):

```bash
sqlite3 retail.db < schema.sql
sqlite3 retail.db < seed_data.sql
sqlite3 retail.db < queries/analysis_queries.sql
```

Or paste the files into any SQL client / [sqliteonline.com](https://sqliteonline.com).

---

## 📊 Key Insights (from the analysis)

> *Revenue analysis excludes `Returned` orders.*

| Metric | Value |
|--------|-------|
| Total Revenue | **$1.14M** |
| Total Profit | **$252K** |
| Profit Margin | **22.1%** |
| Valid Orders | **248** |
| Avg Order Value | **$4,615** |

- 🏆 **Technology** is the top category ($524K), ahead of Furniture ($313K) and Office Supplies ($307K).
- 🌍 **West** ($310K) and **North** ($279K) are the strongest regions; **Central** ($73K) is the biggest growth opportunity.
- 📦 Top products: **Whiteboard**, **Lever Arch**, **MacBook Air**, **Marker Set**, **Executive Chair**.
- 👤 Top customers: **Emma Ahmed**, **David Nguyen**, **John Johnson** — a small set of accounts drives outsized revenue.
- 🔁 Every customer placed **repeat orders** (avg ~6 orders each) — strong retention in the sample.

---

## 🧠 Techniques Demonstrated

| Query | Technique |
|-------|-----------|
| KPIs, revenue by category/region | `JOIN`, `GROUP BY`, aggregation |
| Monthly trend | date functions, grouping |
| Cumulative revenue | `SUM() OVER (ORDER BY ...)` window |
| Product rank in category | `RANK() OVER (PARTITION BY ...)` |
| Month-over-month growth | `LAG() OVER (...)` |
| Customer value tiers | CTE + `CASE` segmentation |
| Discount vs. margin | ratio analysis across dimensions |

All 12 queries are documented in [`queries/analysis_queries.sql`](queries/analysis_queries.sql).

---

## 🛠️ Skills Demonstrated

`SQL` · `Relational Modeling` · `JOINs` · `CTEs` · `Window Functions` · `Aggregation` · `Data Analysis` · `Business Insight`

---

<sub>⭐ Part of my data analytics portfolio. Uses generated sample data. Contact: khanhassan718@yahoo.com</sub>
