"""
Load the 9 Olist CSV files from data/raw/ into a local DuckDB database.

Every column gets an explicit data type (dates as TIMESTAMP, money as
DECIMAL, counts as INTEGER) instead of letting the database guess. That way
date math and sums in the SQL queries behave correctly.

Usage (from the project root):
    .venv\\Scripts\\python.exe scripts\\load_data.py

Output:
    data/olist.duckdb  (ignored by git, rebuild it any time with this script)
"""

from pathlib import Path
import sys

import duckdb

# Paths are resolved relative to this file, so the script works no matter
# which folder you run it from.
PROJECT_ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = PROJECT_ROOT / "data" / "raw"
DB_PATH = PROJECT_ROOT / "data" / "olist.duckdb"

# All Olist timestamps look like "2017-10-02 10:56:33".
TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S"

# One entry per table: (table name, CSV file name, {column: SQL type}).
# The column order must match the order in the CSV header.
# Zip codes and IDs stay VARCHAR: they are labels, not numbers to add up,
# and zip codes can start with a leading zero.
TABLES = [
    ("customers", "olist_customers_dataset.csv", {
        "customer_id": "VARCHAR",
        "customer_unique_id": "VARCHAR",
        "customer_zip_code_prefix": "VARCHAR",
        "customer_city": "VARCHAR",
        "customer_state": "VARCHAR",
    }),
    ("geolocation", "olist_geolocation_dataset.csv", {
        "geolocation_zip_code_prefix": "VARCHAR",
        "geolocation_lat": "DOUBLE",
        "geolocation_lng": "DOUBLE",
        "geolocation_city": "VARCHAR",
        "geolocation_state": "VARCHAR",
    }),
    ("orders", "olist_orders_dataset.csv", {
        "order_id": "VARCHAR",
        "customer_id": "VARCHAR",
        "order_status": "VARCHAR",
        "order_purchase_timestamp": "TIMESTAMP",
        "order_approved_at": "TIMESTAMP",
        "order_delivered_carrier_date": "TIMESTAMP",
        "order_delivered_customer_date": "TIMESTAMP",
        "order_estimated_delivery_date": "TIMESTAMP",
    }),
    ("order_items", "olist_order_items_dataset.csv", {
        "order_id": "VARCHAR",
        "order_item_id": "INTEGER",
        "product_id": "VARCHAR",
        "seller_id": "VARCHAR",
        "shipping_limit_date": "TIMESTAMP",
        "price": "DECIMAL(10,2)",
        "freight_value": "DECIMAL(10,2)",
    }),
    ("order_payments", "olist_order_payments_dataset.csv", {
        "order_id": "VARCHAR",
        "payment_sequential": "INTEGER",
        "payment_type": "VARCHAR",
        "payment_installments": "INTEGER",
        "payment_value": "DECIMAL(10,2)",
    }),
    ("order_reviews", "olist_order_reviews_dataset.csv", {
        "review_id": "VARCHAR",
        "order_id": "VARCHAR",
        "review_score": "INTEGER",
        "review_comment_title": "VARCHAR",
        "review_comment_message": "VARCHAR",
        "review_creation_date": "TIMESTAMP",
        "review_answer_timestamp": "TIMESTAMP",
    }),
    # The original CSV header misspells "length" as "lenght".
    # Because we pass our own column names, the table gets the correct spelling.
    ("products", "olist_products_dataset.csv", {
        "product_id": "VARCHAR",
        "product_category_name": "VARCHAR",
        "product_name_length": "INTEGER",
        "product_description_length": "INTEGER",
        "product_photos_qty": "INTEGER",
        "product_weight_g": "INTEGER",
        "product_length_cm": "INTEGER",
        "product_height_cm": "INTEGER",
        "product_width_cm": "INTEGER",
    }),
    ("sellers", "olist_sellers_dataset.csv", {
        "seller_id": "VARCHAR",
        "seller_zip_code_prefix": "VARCHAR",
        "seller_city": "VARCHAR",
        "seller_state": "VARCHAR",
    }),
    ("category_translation", "product_category_name_translation.csv", {
        "product_category_name": "VARCHAR",
        "product_category_name_english": "VARCHAR",
    }),
]


def columns_literal(columns: dict) -> str:
    """Turn {"a": "INTEGER"} into the DuckDB struct text {'a': 'INTEGER'}."""
    parts = [f"'{name}': '{sql_type}'" for name, sql_type in columns.items()]
    return "{" + ", ".join(parts) + "}"


def main() -> None:
    # Stop early with a helpful message if any CSV is missing.
    missing = [csv for _, csv, _ in TABLES if not (RAW_DIR / csv).exists()]
    if missing:
        print("Missing CSV files in data/raw/:")
        for name in missing:
            print(f"  - {name}")
        print("Download the Olist dataset from Kaggle and unzip it into data/raw/.")
        sys.exit(1)

    con = duckdb.connect(str(DB_PATH))
    print(f"Building {DB_PATH.relative_to(PROJECT_ROOT)}\n")

    for table, csv_name, columns in TABLES:
        csv_path = (RAW_DIR / csv_name).as_posix()
        # CREATE OR REPLACE makes the script safe to re-run.
        # header = true skips the CSV's own header row; our column names are used instead.
        # No ignore_errors: if a value does not fit its type, we want the load to fail loudly.
        con.execute(f"""
            CREATE OR REPLACE TABLE {table} AS
            SELECT *
            FROM read_csv(
                '{csv_path}',
                header = true,
                columns = {columns_literal(columns)},
                timestampformat = '{TIMESTAMP_FORMAT}'
            )
        """)
        rows = con.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        print(f"  {table:<22} {rows:>9,} rows")

    con.close()
    print("\nDone.")


if __name__ == "__main__":
    main()
