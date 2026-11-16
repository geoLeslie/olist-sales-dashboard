# Looker Studio dashboard guide

How to build the one-page dashboard from the CSV files in `outputs/`.

## 1. Which CSV feeds what

| CSV | Used for | Reacts to date filter? |
|---|---|---|
| `07_dashboard_orders.csv` | 4 KPI cards, date filter, monthly trend, state table | Yes |
| `03_late_delivery_reviews.csv` | Review score by delivery delay | No (full period) |
| `04_top_categories.csv` | Top 10 categories | No (full period) |
| `06_payment_methods.csv` | Payment method share | No (full period) |

Only `07` has a date on every row, so only charts built from it change when you move the date filter. The other three are summaries of the whole period (Jan 2017 to Aug 2018). Put a small text label "Full period" above those charts so viewers are not confused.

## 2. Add the data

The easiest way is the **File Upload** connector (no Google Sheets needed):

1. Go to [lookerstudio.google.com](https://lookerstudio.google.com) and click **Blank report**.
2. In "Add data to report", search for **File Upload**, then upload `07_dashboard_orders.csv`. Name the data source `orders`.
3. Click **Add data** (top menu: Resource > Manage added data sources > Add a data source) and repeat for `03`, `04` and `06`.

If you prefer Google Sheets: import each CSV into a Sheet, but first set **File > Settings > Locale** to **United States**. With the Indonesia locale, Sheets reads `111798.36` wrong because Indonesia uses a comma for decimals.

## 3. Fix field types in the `orders` data source

Resource > Manage added data sources > `orders` > Edit:

| Field | Type | Default aggregation |
|---|---|---|
| purchase_date | Date (YYYY-MM-DD) | None |
| customer_state | Text | None |
| revenue | Currency (BRL) | Sum |
| review_score | Number | Average |
| delivery_days | Number | Average |
| is_late | Number | Average |

Then click **Add a field** and create:

- `late_rate` with formula `AVG(is_late)`, type **Percent**

## 4. Layout

```
+---------------------------------------------------------------+
| Olist Sales Dashboard                      [ Date range ]      |
+---------------+---------------+---------------+---------------+
| Total revenue | Total orders  | Avg review    | % late        |
+---------------+---------------+---------------+---------------+
| Monthly revenue and orders (line chart, full width)           |
+-------------------------------+-------------------------------+
| Review score by delivery delay| Top 10 categories by revenue  |
+-------------------------------+-------------------------------+
| Delivery by state (table)     | Payment method share (donut)  |
+-------------------------------+-------------------------------+
```

## 5. Build each part

**Title.** Insert > Text: "Olist Sales Dashboard (Jan 2017 to Aug 2018)".

**Date filter.** Insert > Date range control, put it top right. Set the default to Custom: 1 Jan 2017 to 31 Aug 2018.

**KPI cards** (Insert > Scorecard, data source `orders`, make 4):

| Card | Metric | Format |
|---|---|---|
| Total revenue | revenue (Sum) | Currency, compact number |
| Total orders | Record Count | Number |
| Avg review score | review_score (Average) | 2 decimals |
| % late deliveries | late_rate | Percent, 1 decimal |

Expected values for the full period: R$13.18M, 96,203 orders, 4.16, 6.8%.

**Chart 1: Monthly trend** (Insert > Time series, source `orders`)
- Dimension: purchase_date, then click the calendar icon and set granularity to **Year Month**
- Metrics: revenue (Sum), Record Count
- Style tab: put Record Count on the right axis

**Chart 2: Review score by delivery delay** (Insert > Bar chart, source `03`)
- Dimension: delivery_group
- Metric: avg_review_score (set aggregation to Average)
- Sort: delivery_group ascending (the "1.", "2." prefixes keep the order right)

**Chart 3: Top 10 categories** (Insert > Bar chart, horizontal, source `04`)
- Dimension: category
- Metric: revenue (Sum)
- Sort: revenue descending

**Chart 4: Delivery by state** (Insert > Table, source `orders`)
- Dimension: customer_state
- Metrics: Record Count, delivery_days (Average), late_rate
- Sort: delivery_days descending
- Style tab: set late_rate to "Heatmap" so the worst states stand out

Optional: use a Geo chart instead. Create a field `state_code` = `CONCAT("BR-", customer_state)`, set its type to Geo > Country subdivision (1st level), and use it as the dimension with late_rate as the color metric.

**Chart 5: Payment method share** (Insert > Pie chart, donut style, source `06`)
- Dimension: payment_type
- Metric: total_paid (Sum)

## 6. Finish

1. Theme and layout > pick a simple theme, keep 2 or 3 colors.
2. Click **View** and test that the date filter changes the KPI cards, trend and state table.
3. Share > Manage access > "Anyone with the link can view". Copy the link into the README.
4. Take a screenshot (full page) and save it as `docs/screenshots/dashboard.png`.
