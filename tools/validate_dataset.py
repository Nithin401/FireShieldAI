import argparse
import pandas as pd
import numpy as np
import os
import sys

def validate(input_csv, save_report=True):
    print("=" * 65)
    print(f" [VALIDATION] FIRESHIELD AI - RAW DATASET VALIDATION REPORT")
    print(f" Target File: {input_csv}")
    print("=" * 65)

    if not os.path.exists(input_csv):
        print(f"[ERROR] File not found: {input_csv}")
        return False

    try:
        df = pd.read_csv(input_csv)
    except Exception as e:
        print(f"[ERROR] Malformed CSV File: Could not parse CSV: {e}")
        return False

    report = {
        "file_name": input_csv,
        "total_rows": len(df),
        "missing_values": {},
        "invalid_timestamps": 0,
        "duplicate_timestamps": 0,
        "invalid_flame_raw": 0,
        "invalid_flame_digital": 0,
        "invalid_servo_angle": 0,
        "sampling_intervals": {},
        "status": "PASS"
    }

    # Required columns check
    required_cols = [
        "timestamp_ms", "experiment_id", "condition", "room_id",
        "device_id", "flame_raw", "flame_digital", "servo_angle"
    ]
    missing_cols = [col for col in required_cols if col not in df.columns]
    if missing_cols:
        print(f"[ERROR] Missing Required Columns: {missing_cols}")
        report["status"] = "FAIL"
        return report

    # 1. Missing values
    for col in required_cols:
        null_count = df[col].isnull().sum()
        report["missing_values"][col] = int(null_count)
        if null_count > 0:
            report["status"] = "WARNING"

    # 2. Check numeric types
    df['flame_raw'] = pd.to_numeric(df['flame_raw'], errors='coerce')
    df['flame_digital'] = pd.to_numeric(df['flame_digital'], errors='coerce')
    df['servo_angle'] = pd.to_numeric(df['servo_angle'], errors='coerce')
    df['timestamp_ms'] = pd.to_numeric(df['timestamp_ms'], errors='coerce')

    # 3. Invalid value bounds
    invalid_raw = df[(df['flame_raw'] < 0) | (df['flame_raw'] > 1024)]
    report["invalid_flame_raw"] = len(invalid_raw)

    invalid_dig = df[~df['flame_digital'].isin([0, 1])]
    report["invalid_flame_digital"] = len(invalid_dig)

    invalid_angle = df[(df['servo_angle'] < 0) | (df['servo_angle'] > 180)]
    report["invalid_servo_angle"] = len(invalid_angle)

    # 4. Timestamp checks
    report["duplicate_timestamps"] = int(df.duplicated(subset=['timestamp_ms']).sum())
    
    # Check monotonic increase
    ts_diffs = df['timestamp_ms'].diff().dropna()
    negative_intervals = ts_diffs[ts_diffs <= 0]
    report["invalid_timestamps"] = len(negative_intervals)

    if len(ts_diffs) > 0:
        report["sampling_intervals"] = {
            "mean_ms": round(float(ts_diffs.mean()), 2),
            "std_ms": round(float(ts_diffs.std()), 2),
            "min_ms": float(ts_diffs.min()),
            "max_ms": float(ts_diffs.max())
        }

    # Evaluate Overall Status
    if report["invalid_flame_raw"] > 0 or report["invalid_flame_digital"] > 0 or report["invalid_servo_angle"] > 0:
        report["status"] = "FAIL"

    # Print Summary
    print(f" Overall Status:            [{report['status']}]")
    print(f" Total Rows / Samples:      {report['total_rows']}")
    print(f" Missing Values:            {report['missing_values']}")
    print(f" Invalid Timestamps:        {report['invalid_timestamps']}")
    print(f" Duplicate Timestamps:      {report['duplicate_timestamps']}")
    print(f" Invalid flame_raw (0-1024):{report['invalid_flame_raw']}")
    print(f" Invalid flame_digital(0/1):{report['invalid_flame_digital']}")
    print(f" Invalid servo_angle(0-180):{report['invalid_servo_angle']}")
    if report["sampling_intervals"]:
        print(f" Sampling Interval (Mean):  {report['sampling_intervals']['mean_ms']} ms")
        print(f" Sampling Interval (Min/Max): {report['sampling_intervals']['min_ms']} ms / {report['sampling_intervals']['max_ms']} ms")
    print("=" * 65)

    # Save report separately without modifying original raw CSV
    if save_report:
        os.makedirs("reports", exist_ok=True)
        base_name = os.path.basename(input_csv).replace(".csv", "_validation.txt")
        report_path = os.path.join("reports", base_name)
        with open(report_path, "w", encoding="utf-8") as f:
            for k, v in report.items():
                f.write(f"{k}: {v}\n")
        print(f"[SAVE] Validation report saved to: {report_path}")

    return report

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Validate Raw Flame Sensor Dataset")
    parser.add_argument("--input", required=True, help="Path to raw dataset CSV file")
    args = parser.parse_args()

    validate(args.input)
