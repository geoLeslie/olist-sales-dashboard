"""
Run every .sql file in sql/ and save each result to outputs/<name>.csv.

Usage (from the project root):
    .venv\\Scripts\\python.exe scripts\\run_queries.py
"""

from pathlib import Path

import duckdb

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DB_PATH = PROJECT_ROOT / "data" / "olist.duckdb"
SQL_DIR = PROJECT_ROOT / "sql"
OUTPUT_DIR = PROJECT_ROOT / "outputs"


def main() -> None:
    # read_only so we never change the database by accident
    # (close DBeaver first, it locks the file)
    con = duckdb.connect(str(DB_PATH), read_only=True)

    for sql_file in sorted(SQL_DIR.glob("*.sql")):
        query = sql_file.read_text(encoding="utf-8")
        df = con.execute(query).df()

        out_file = OUTPUT_DIR / f"{sql_file.stem}.csv"
        df.to_csv(out_file, index=False)
        print(f"{sql_file.name:<32} {len(df):>7,} rows -> outputs/{out_file.name}")

    con.close()


if __name__ == "__main__":
    main()
