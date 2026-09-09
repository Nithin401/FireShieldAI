import argparse
import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

def analyze_raw_dataset(input_csv):
    print("=" * 65)
    print(f" [ANALYSIS] FIRESHIELD AI - RAW DATASET ANALYSIS")
    print(f" Dataset: {input_csv}")
    print("=" * 65)

    if not os.path.exists(input_csv):
        print(f"[ERROR] File not found: {input_csv}")
        return

    df = pd.read_csv(input_csv)
    
    if len(df) == 0:
        print("[ERROR] Dataset is empty.")
        return

    # Basic calculations
    sample_count = len(df)
    duration_ms = df['timestamp_ms'].max() - df['timestamp_ms'].min() if 'timestamp_ms' in df.columns else 0
    duration_sec = duration_ms / 1000.0

    flame_raw = df['flame_raw'].dropna()

    stats = {
        "sample_count": sample_count,
        "duration_seconds": round(duration_sec, 2),
        "sampling_rate_hz": round(sample_count / duration_sec, 2) if duration_sec > 0 else 0,
        "flame_raw_min": float(flame_raw.min()),
        "flame_raw_max": float(flame_raw.max()),
        "flame_raw_mean": round(float(flame_raw.mean()), 2),
        "flame_raw_median": float(flame_raw.median()),
        "flame_raw_std": round(float(flame_raw.std()), 2),
        "percentile_25": float(np.percentile(flame_raw, 25)),
        "percentile_50": float(np.percentile(flame_raw, 50)),
        "percentile_75": float(np.percentile(flame_raw, 75)),
    }

    print(f" Sample Count:         {stats['sample_count']}")
    print(f" Total Duration:       {stats['duration_seconds']} seconds")
    print(f" Approx Sampling Rate: {stats['sampling_rate_hz']} Hz")
    print(f" Flame Raw Min / Max:  {stats['flame_raw_min']} / {stats['flame_raw_max']}")
    print(f" Flame Raw Mean / Std: {stats['flame_raw_mean']} +- {stats['flame_raw_std']}")
    print(f" Flame Raw Median:     {stats['flame_raw_median']}")
    print(f" Percentiles (25/50/75): {stats['percentile_25']} / {stats['percentile_50']} / {stats['percentile_75']}")
    print("=" * 65)

    # Save summary report separately under reports/
    os.makedirs("reports", exist_ok=True)
    base_filename = os.path.basename(input_csv).replace(".csv", "")
    report_text_path = os.path.join("reports", f"{base_filename}_summary.txt")

    with open(report_text_path, "w", encoding="utf-8") as f:
        f.write("FIRESHIELD AI - EXPERIMENT SUMMARY REPORT\n")
        f.write("=" * 50 + "\n")
        for k, v in stats.items():
            f.write(f"{k}: {v}\n")

    print(f"[SAVE] Analysis summary saved to: {report_text_path}")

    # Plot distribution & trace separately under reports/plots/
    os.makedirs(os.path.join("reports", "plots"), exist_ok=True)
    plot_path = os.path.join("reports", "plots", f"{base_filename}_plot.png")

    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 8))
    
    # Trace over time
    ax1.plot(df.index, df['flame_raw'], label='Flame Raw (A0)', color='red', alpha=0.8)
    ax1.axhline(stats['flame_raw_mean'], color='blue', linestyle='--', label=f'Mean ({stats["flame_raw_mean"]})')
    ax1.set_title(f'Raw Flame Signal Trace - {base_filename}')
    ax1.set_ylabel('Raw Reading (0-1024)')
    ax1.legend()
    ax1.grid(True)

    # Histogram distribution
    ax2.hist(flame_raw, bins=30, color='orange', edgecolor='black', alpha=0.7)
    ax2.set_title('Flame Signal Value Distribution')
    ax2.set_xlabel('Raw Value')
    ax2.set_ylabel('Frequency')
    ax2.grid(True)

    plt.tight_layout()
    plt.savefig(plot_path)
    plt.close()
    print(f"[SAVE] Signal plot saved to: {plot_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Analyze Raw Flame Dataset")
    parser.add_argument("--input", required=True, help="Path to raw CSV dataset")
    args = parser.parse_args()

    analyze_raw_dataset(args.input)
