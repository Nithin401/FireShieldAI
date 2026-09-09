import serial
import serial.tools.list_ports
import csv
import time
import datetime
import os
import argparse
import sys

def find_serial_port():
    ports = list(serial.tools.list_ports.comports())
    for p in ports:
        if 'CH340' in p.description or 'Arduino' in p.description or 'USB' in p.description or 'CP210' in p.description:
            return p.device
    if len(ports) > 0:
        return ports[0].device
    return None

def main():
    parser = argparse.ArgumentParser(description="FireShieldAI - Immutable Raw Sensor Data Logger")
    parser.add_argument('--port', type=str, help='Serial COM port (e.g., COM3, /dev/ttyUSB0)')
    parser.add_argument('--baud', type=int, default=115200, help='Baud rate (default: 115200)')
    parser.add_argument('--session', '--experiment_id', type=str, required=True, dest='session', help='Unique Experiment ID (e.g., NORMAL_001, FIRE_TEST_001)')
    parser.add_argument('--condition', type=str, required=True, choices=['NORMAL', 'FIRE', 'FALSE_ALARM'], help='Experiment condition label')
    parser.add_argument('--room', type=str, default='ROOM_1', help='Room / Location ID (default: ROOM_1)')
    parser.add_argument('--device', type=str, default='ESP1', help='Device ID (default: ESP1)')
    args = parser.parse_args()

    port = args.port if args.port else find_serial_port()
    if not port:
        print("❌ Error: Could not automatically detect an ESP1 serial port.")
        print("Please connect your ESP1 via USB or specify port manually using '--port COM3'")
        sys.exit(1)

    print("=" * 65)
    print(" 🔥 FIRESHIELD AI - IMMUTABLE RAW DATASET LOGGER")
    print(f" Port: {port} | Baud: {args.baud}")
    print(f" Session: {args.session} | Condition: {args.condition} | Room: {args.room}")
    print("=" * 65)

    # Immutable raw directory layout
    condition_folder = args.condition.lower()
    raw_dir = os.path.join("data", "raw", condition_folder)
    os.makedirs(raw_dir, exist_ok=True)

    date_str = datetime.datetime.now().strftime("%Y-%m-%d_%H%M%S")
    filename = os.path.join(raw_dir, f"{args.session}_{date_str}.csv")

    # Immutable CSV Schema
    fieldnames = [
        "timestamp_ms",
        "experiment_id",
        "condition",
        "room_id",
        "device_id",
        "flame_raw",
        "flame_digital",
        "servo_angle"
    ]

    samples_count = 0
    start_time = time.time()

    try:
        ser = serial.Serial(port, args.baud, timeout=2)
        time.sleep(2)  # Wait for ESP1 serial reset

        with open(filename, mode='w', newline='', encoding='utf-8') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            csvfile.flush()

            print(f"\n📂 Recording raw dataset to: {filename}")
            print("Press Ctrl+C at any time to stop safely.\n")

            while True:
                if ser.in_waiting > 0:
                    try:
                        line = ser.readline().decode('utf-8', errors='ignore').strip()
                        
                        # Skip header lines or diagnostic output
                        if not line or line.startswith("timestamp_ms") or line.startswith("=") or line.startswith("SMART"):
                            continue

                        parts = line.split(',')
                        if len(parts) >= 6:
                            # Incoming format: esp_timestamp_ms, device_id, room_id, flame_raw, flame_digital, servo_angle
                            esp_ts, dev_id, rm_id, flame_raw, flame_dig, servo_ang = parts[:6]

                            # Basic Validation
                            if not esp_ts.isdigit() or not flame_raw.isdigit():
                                continue

                            row = {
                                "timestamp_ms": int(esp_ts),
                                "experiment_id": args.session,
                                "condition": args.condition,
                                "room_id": rm_id if rm_id else args.room,
                                "device_id": dev_id if dev_id else args.device,
                                "flame_raw": int(flame_raw),
                                "flame_digital": int(flame_dig),
                                "servo_angle": int(servo_ang)
                            }

                            writer.writerow(row)
                            csvfile.flush()  # Continuous disk flush

                            samples_count += 1
                            elapsed = time.time() - start_time
                            sys.stdout.write(
                                f"\r SAMPLES: {samples_count:5d} | ELAPSED: {elapsed:6.1f}s | "
                                f"RAW: {row['flame_raw']:4d} | DIGITAL: {row['flame_digital']} | ANGLE: {row['servo_angle']:3d}° "
                            )
                            sys.stdout.flush()

                    except (ValueError, IndexError):
                        continue

    except KeyboardInterrupt:
        print("\n\n⏹️ Logging safely stopped by user (Ctrl+C).")
    except serial.SerialException as e:
        print(f"\n❌ Serial connection error: {e}")
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()

        elapsed_total = time.time() - start_time
        print("=" * 65)
        print(" 💾 IMMUTABLE RAW DATASET SAVED SUCCESSFULLY")
        print(f" File Path:       {filename}")
        print(f" Total Samples:   {samples_count}")
        print(f" Total Duration:  {elapsed_total:.2f} seconds")
        print("=" * 65)

if __name__ == "__main__":
    main()
