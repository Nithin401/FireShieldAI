# FireShield AI - Day-Wise Implementation & Change History Log

This document tracks all work performed on the **FireShield AI** platform chronologically day-by-day, detailing **what changes were made**, **why they were made**, and their **current status**.

---

## 📅 Day 1: System Audit & Single-Sensor Datalogging Foundation
**Date:** September 8, 2026

### 1. Work Completed
- **Project Structure Setup:** Created standard directories (`firmware/`, `tools/`, `ai/`, `ml/`, `docs/`, `data/`, `reports/`).
- **ESP1 Datalogging Firmware:** Created `firmware/esp1_detection/esp1_detection.ino` and `config.h` to output machine-readable raw analog flame sensor data over USB Serial.
- **Python Serial Logger:** Developed `tools/flame_data_logger.py` with continuous CSV flushing and keyboard interrupt safety.
- **AI Signal Analysis Engine:** Built `ai/preprocessing.py`, `ai/features.py`, `ai/anomaly_detection.py`, `ai/risk_engine.py`, and `ai/analyze_dataset.py` to extract rolling variance, calculate dynamic baselines, and compute 0-100% risk scores.
- **Supervised ML Skeleton:** Built `ml/train.py` and `ml/evaluate.py` for future model evaluation.

### 2. Rationale & Why Changes Were Made
- **Why avoid premature ML?** With only a single physical IR flame sensor initially available, jumping straight to complex neural networks or claiming false ML accuracy would be invalid. The rule-based + statistical anomaly engine provides immediate signal intelligence while gathering real hardware datasets.
- **Why CSV Serial output on ESP1?** To capture raw sensor behavior without Wi-Fi overhead or packet drops during initial noise calibration.

---

## 📅 Day 2: Full System Audit & Telemetry Ingestion Bridge
**Date:** September 9, 2026

### 1. Work Completed
- **Comprehensive FireShield AI Application Audit:** Inspected all 12 Flutter screens and data layers; documented implemented vs. mock features in `docs/firesheild_app_audit.md`.
- **Exposed Credentials Remediation:** Identified hardcoded Telegram tokens and Wi-Fi passwords in legacy code for security remediation.
- **ESP1 Dual Wi-Fi + ESP-NOW Firmware:** Developed `firmware/esp1_detection/esp1_wifi_telemetry.ino` combining ESP-NOW scanning, Telegram alert triggers, and Wi-Fi HTTP POST telemetry (`POST /api/telemetry`).
- **ESP2 Response Node Firmware:** Verified `firmware/esp2_response/esp2_response.ino` for ESP-NOW reception, servo aiming, relay/pump control, and 1000ms safety timeout protection.
- **Python Backend & Firestore Engine:** Developed `tools/backend_server.py` running a Flask REST server, integrating `ai/risk_engine.py`, and streaming real-time device states to Google Cloud Firestore (`devices/{deviceId}`).

### 2. Rationale & Why Changes Were Made
- **Why add Wi-Fi HTTP POST to ESP1?** ESP1 needs to inform both the local ESP2 response node (via ESP-NOW) AND the cloud/app dashboard (via Wi-Fi) simultaneously so local physical response works even if internet fails.
- **Why build `backend_server.py`?** Serves as an ingestion bridge between microcontrollers and Firestore while running heavy Python AI Risk computations off-device.

---

## 📅 Day 3: Flutter App Integration & Single Repository Consolidation
**Date:** September 9, 2026 (Continued)

### 1. Work Completed
- **Updated `DeviceModel`:** Added `flameRaw`, `fireAngle`, `riskScore`, `fireState`, and `responseStatus` to `D:\FireShieldAI\lib\domain\models\device_model.dart`.
- **Implemented `FirestoreDeviceRepository`:** Connected live HTTP REST/Firestore stream to Flutter presentation layer.
- **Dashboard & Details UI Binding:** Bound System Alert Banner and Active Zone Cards to real AI `fireState` and `riskScore`. Bound `DeviceDetailsScreen` to render live A0 raw values, target angles, and risk percentage charts.
- **Form Persistence:** Updated `AddDeviceScreen` to register new detection nodes directly with the backend and Firestore stream.
- **Single Monorepo Consolidation:** Consolidated all firmware, AI modules, tools, docs, datasets, and Flutter app code into **one unified project (`D:\FireShieldAI`)**.
- **GitHub Deployment:** Committed and pushed all consolidated code to [https://github.com/Nithin401/FireShieldAI.git](https://github.com/Nithin401/FireShieldAI.git) on branch `main`.

### 2. Rationale & Why Changes Were Made
- **Why consolidate into `D:\FireShieldAI`?** Having firmware, AI backend scripts, and Flutter frontend split across two root directories caused version fragmentation. A single unified monorepo simplifies deployment and GitHub tracking.
- **Why update `DeviceModel`?** The app previously rendered hardcoded mock values. Adding flame raw and fire angle fields enables the UI to reflect physical hardware telemetry in real time.

---

## 📋 Ongoing Logging Protocol
For every future modification:
1. Record the date and milestone title.
2. List exact files modified/created under **Work Completed**.
3. Document technical decisions and rationale under **Why Changes Were Made**.
4. Stage, commit, and push to GitHub.
