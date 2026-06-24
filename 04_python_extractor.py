# Author: Ranjeet Kumar
# Project: Banking ETL Pipeline
# Script: Python Data Extractor

import pandas as pd
import pyodbc
import logging
import os
from datetime import datetime
from pathlib import Path

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s | %(levelname)s | %(message)s'
)
log = logging.getLogger(__name__)

DB_CONFIG = {
    "server":   os.getenv("SQL_SERVER",   "YOUR_SERVER"),
    "database": os.getenv("SQL_DATABASE", "BankingETL_DB"),
    "driver":   "{ODBC Driver 18 for SQL Server}",
    "trusted":  True
}

INPUT_FOLDER   = Path("./data/input")
ARCHIVE_FOLDER = Path("./data/archive")
BATCH_SIZE     = 5000

def get_connection():
    conn_str = (
        f"DRIVER={DB_CONFIG['driver']};"
        f"SERVER={DB_CONFIG['server']};"
        f"DATABASE={DB_CONFIG['database']};"
        "Trusted_Connection=yes;"
    )
    return pyodbc.connect(conn_str, autocommit=False)

def extract_file(filepath):
    if filepath.suffix.lower() == ".csv":
        df = pd.read_csv(filepath, dtype=str)
    else:
        df = pd.read_excel(filepath, dtype=str)
    df.columns = [c.strip().upper().replace(" ", "_") for c in df.columns]
    log.info(f"Extracted {len(df)} rows from {filepath.name}")
    return df

def load_to_staging(df, filename, conn):
    cursor = conn.cursor()
    insert_sql = """
        INSERT INTO staging.RawTransactions
            (SourceFileName, AccountNumber, TransactionDate,
             TransactionAmount, TransactionType, BranchCode,
             IFSC_Code, CustomerName, RawData)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    """
    batch = []
    rows_inserted = 0

    for _, row in df.iterrows():
        batch.append((
            filename,
            row.get("ACCOUNT_NUMBER"),
            row.get("TRANSACTION_DATE"),
            row.get("TRANSACTION_AMOUNT"),
            row.get("TRANSACTION_TYPE"),
            row.get("BRANCH_CODE"),
            row.get("IFSC_CODE"),
            row.get("CUSTOMER_NAME"),
            str(row.to_dict())
        ))
        if len(batch) >= BATCH_SIZE:
            cursor.executemany(insert_sql, batch)
            rows_inserted += len(batch)
            batch = []

    if batch:
        cursor.executemany(insert_sql, batch)
        rows_inserted += len(batch)

    conn.commit()
    log.info(f"Loaded {rows_inserted} rows to staging")
    return rows_inserted

def run_etl_transform(conn):
    cursor = conn.cursor()
    cursor.execute("EXEC etl.usp_TransformBankingData @Debug = 1")
    conn.commit()
    log.info("ETL transformation completed.")

def archive_file(filepath):
    ARCHIVE_FOLDER.mkdir(parents=True, exist_ok=True)
    dest = ARCHIVE_FOLDER / f"{datetime.now().strftime('%Y%m%d_%H%M%S')}_{filepath.name}"
    filepath.rename(dest)
    log.info(f"Archived: {filepath.name}")

def main():
    log.info("Banking ETL Pipeline Started")
    files = list(INPUT_FOLDER.glob("*.csv")) + \
            list(INPUT_FOLDER.glob("*.xlsx"))

    if not files:
        log.warning("No input files found.")
        return

    conn = get_connection()
    try:
        for filepath in files:
            try:
                df = extract_file(filepath)
                load_to_staging(df, filepath.name, conn)
                run_etl_transform(conn)
                archive_file(filepath)
                log.info(f"✅ {filepath.name} done!")
            except Exception as e:
                log.error(f"❌ Failed: {filepath.name} — {e}")
                conn.rollback()
    finally:
        conn.close()
    log.info("Pipeline Finished.")

if __name__ == "__main__":
    main()
