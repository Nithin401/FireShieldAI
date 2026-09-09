# FireShieldAI: Comprehensive Technical Audit & System Report

**Date:** September 9, 2026  
**Audited Repository:** `D:\FireShieldAI` (Unified Monorepo)  
**System Scope:** Physical Hardware (ESP1 & ESP2 Firmware), Data Pipeline, Python AI Risk Engine, Backend Ingestion Services, Cloud Firestore Architecture, and Flutter Presentation App.

---

# 1. EXECUTIVE SUMMARY

Honest, grounded summary of the actual status of the FireShieldAI repository today:

- **What is actually working today?**
  1. **ESP1 Physical Datalogger & Telemetry:** ESP1 firmware reads raw analog signals from the IR flame sensor (`A0`), performs servo angle scanning, streams CSV data over USB Serial (`esp1_detection.ino`), and transmits HTTP JSON payloads (`esp1_wifi_telemetry.ino`) to the Python backend.
  2. **ESP1 $\rightarrow$ ESP2 Physical Response Link:** Physical ESP-NOW communication (`header 0xAA`, `fire`, `angle`, `packetID`) on Wi-Fi Channel 6 between ESP1 and ESP2 works cleanly. ESP2 receives packets, positions the aiming servo, and triggers the relay, water pump, buzzer, and LED with a 1000ms safety timeout.
  3. **Python AI Risk Engine & Ingestion Server:** `tools/backend_server.py` ingests telemetry via `POST /api/telemetry`, calculates dynamic baseline deviations, rolling variances, first-derivative rate-of-change, Z-Score anomaly scores, and multi-factor 0–100% risk scores (`ai/risk_engine.py`).
  4. **Flutter Reactive Presentation UI Shell:** Flutter app (`D:\FireShieldAI`) built with Material 3, Riverpod 3.3.2, and GoRouter 17.3.0. Features dynamic alert banners, sensor cards, detailed hardware diagnostic lists, live location map centering, and time-series line charts (`fl_chart`).

- **What is partially working?**
  1. **Backend Telemetry $\rightarrow$ App Telemetry Stream:** `FirestoreDeviceRepository` reads from `http://localhost:5000/api/devices` to update Riverpod UI state. Works in local REST mode; direct cloud streaming requires configuring `serviceAccountKey.json`.
  2. **Firebase Firestore Cloud Storage:** Schema logic and Admin SDK code exist in `tools/backend_server.py` and commented blocks in `firestore_device_repository.dart`. When `serviceAccountKey.json` is omitted, it operates in in-memory fallback mode.
  3. **Add Device & Notification UI Streams:** UI forms exist and send POST requests to the backend, but persistent cloud storage depends on active Firestore credentials.

- **What is only UI/demo?**
  1. **Reports Screen Data:** Choice chips ('Daily', 'Weekly', 'Monthly') generate numbers via `Random()`. Export PDF/CSV buttons display SnackBars without compiling actual PDF documents.
  2. **Push Notifications:** `PushNotificationService` displays a local Flutter `AlertDialog` (`simulateIncomingFireAlert`). Real FCM token dispatch is commented out in Dart.

- **What is missing?**
  1. **Multi-Sensor Hardware Fusion:** Physical hardware currently uses ONLY the IR Flame sensor on ESP1. MQ-2 (gas/smoke), BME280 (temperature/humidity), and DS18B20 are absent from physical hardware.
  2. **Trained Supervised ML Model on Real Data:** Model training scripts (`ml/train.py`, `ml/evaluate.py`) are implemented skeletons. No real labeled dataset (`labeled_data.csv`) collected across multiple physical fire test sessions currently exists.
  3. **ESP2 Status Feedback Channel:** ESP2 is a pure receiver; it does not broadcast its status back to ESP1 or the backend.

---

# 2. CURRENT ARCHITECTURE

```text
[ PHYSICAL HARDWARE ]
  IR Flame Sensor (A0 / D5) ──► ESP1 NodeMCU (Scanning Servo D6)
                                   ├── ESP-NOW (Ch 6, Packet 0xAA) ──► ESP2 NodeMCU (Servo D6, Relay D1, Buzzer D2, LED D5)
                                   └── Wi-Fi (HTTP POST Payload) ───┐
                                                                    │
[ BACKEND & AI LAYER ]                                              │
  Python Flask Server (`tools/backend_server.py`) ◄──────────────────┘
    ├── Rolling Features & Rate of Change (`ai/features.py`)
    ├── Dynamic Baseline & Z-Score Anomaly (`ai/anomaly_detection.py`)
    ├── Rule-Based Multi-Factor Risk Engine (`ai/risk_engine.py`)
    └── Cloud Sync Manager
          ├── (Primary) Google Cloud Firestore (`devices`, `readings`, `alerts`)
          └── (Fallback) In-Memory Python Dict

[ APPLICATION LAYER ]
  Flutter Web/Desktop/Mobile (`D:\FireShieldAI`)
    ├── `repository_providers.dart` (Riverpod Stream)
    ├── `FirestoreDeviceRepository` (HTTP REST / Firestore Client)
    ├── `DashboardScreen` (Live System Alert Banner & Risk Cards)
    ├── `DeviceDetailsScreen` (Raw A0 Flame Signal, Fire Angle, ESP2 Status)
    └── `MapScreen` (Google Maps Live Location & Hardware Markers)
```

---

# 3. HARDWARE STATUS

### ESP1 (Detection Node)
- **Pins:** `A0` (Analog flame raw), `GPIO 14 / D5` (Digital flame read), `GPIO 12 / D6` (Scan servo).
- **Sensors:** 1x LM393-based IR Flame Sensor Module.
- **Servo:** SG90 micro servo scanning 0° to 180° in 3° steps every 40ms.
- **Scanning Logic:** Sweeps back and forth; locks angle upon flame detection (`flameDetected()`).
- **Fire Detection Logic:** Digital read threshold (active LOW) + Analog raw sampling on A0.
- **Angle Calculation:** Direct servo position (`scanAngle`) recorded at the moment of detection.
- **ESP-NOW Transmission:** Sends 7-byte `FireData` struct (`header=0xAA`, `fire`, `angle`, `packetID`) to ESP2 MAC address every 80ms.
- **Wi-Fi:** Connects in `WIFI_STA` mode.
- **Telegram Alert:** `UniversalTelegramBot` sends HTTPS alert messages (`sendTelegramAlert()`).
- **Packet Format:** Struct `FireData { uint8_t header; uint8_t fire; uint8_t angle; uint32_t packetID; }`.
- **Failure Handling:** WiFi auto-reconnect loop every 10 seconds.
- **Status:** **ACTUALLY WORKING** (Hardware firmware compiled and verified in `esp1_wifi_telemetry.ino`).

### ESP2 (Response Node)
- **Pins:** `GPIO 12 / D6` (Aim servo), `GPIO 5 / D1` (Relay), `GPIO 4 / D2` (Buzzer), `GPIO 14 / D5` (LED).
- **Servo:** SG90 micro servo aiming at received `fireAngle` with configurable offset (`SERVO_OFFSET`).
- **Relay:** Active LOW relay controlling 5V DC mini water pump.
- **Buzzer & LED:** Activated simultaneously during fire state.
- **ESP-NOW Reception:** Callback `onDataReceive()` parses incoming payload, verifies header `0xAA` and ESP1 MAC.
- **Angle Handling:** Constrains received angle (5° to 175°) and applies reverse/offset calibration.
- **Timeout Safety:** `SIGNAL_TIMEOUT` (1000ms). If no valid ESP1 packet arrives within 1 second, automatically turns OFF relay, pump, buzzer, and LED.
- **Response Activation:** Activates pump and servo aiming instantly upon receiving `fire == 1`.
- **Status:** **ACTUALLY WORKING** (Hardware firmware compiled and verified in `esp2_response.ino`).

### Hardware Communication Compatibility Verification
- **MAC Addresses:** Matched across firmware configs (`ESP1_MAC: B4:8A:0A:E3:D2:61`, `ESP2_MAC: 48:3F:DA:5F:0C:55`).
- **Wi-Fi Channel:** Forced to Channel 6 on both nodes (`wifi_set_channel(6)`).
- **Packet Structure & Size:** Identical `FireData` 7-byte struct on both sides.
- **Result:** ESP1 and ESP2 **can communicate physically over ESP-NOW**.

---

# 4. SOFTWARE STATUS

- **Frontend (Flutter 3.x, Material 3):** **ACTUALLY WORKING** (Clean Riverpod state architecture, GoRouter navigation, zero compilation errors).
- **Backend (Python Flask REST Server):** **ACTUALLY WORKING** (`tools/backend_server.py` running on `http://0.0.0.0:5000`).
- **Database (Cloud Firestore):** **PARTIALLY WORKING / SIMULATION FALLBACK** (Supported via Admin SDK in Python backend; operates in local memory mode if `serviceAccountKey.json` is omitted).
- **APIs:** `POST /api/telemetry` and `GET /api/devices` implemented and verified.
- **Notifications:** **UI ONLY / SIMULATED** (Local `AlertDialog` popup; FCM dispatch commented out).

---

# 5. AI/ML STATUS

### 1. Rule-Based Logic
- **Implementation:** `ai/risk_engine.py` (RiskEngine class).
- **Inputs:** Baseline deviation (`deviation_from_baseline`), Rate of Change (`first_derivative`), Z-Score anomaly flag.
- **Output:** Risk Score (0 - 100%) and Discrete State (`SAFE`, `WARNING`, `HIGH_RISK`, `FIRE`).
- **Thresholds:** Risk < 30% $\rightarrow$ `SAFE`; Risk < 60% $\rightarrow$ `WARNING`; Risk < 85% $\rightarrow$ `HIGH_RISK`; Risk $\ge$ 85% $\rightarrow$ `FIRE`.
- **Persistence Check:** Requires 3 consecutive high-risk samples before elevating score to prevent single-sample noise spikes.
- **Status:** **ACTUALLY WORKING (Rule-Based & Statistical Anomaly Engine)**.

### 2. Statistical Anomaly Detection
- **Implementation:** `ai/anomaly_detection.py`.
- **Algorithm:** Rolling Median Baseline Estimation (window=50) + Rolling Z-Score (`z = (x - mean) / std`).
- **Status:** **ACTUALLY WORKING**.

### 3. Machine Learning (Supervised ML)
- **Implementation:** `ml/train.py`, `ml/evaluate.py`.
- **Algorithms Implemented:** Logistic Regression, Decision Tree, Random Forest, Support Vector Machine (SVM).
- **Current Status:** **CODE EXISTS BUT NOT INTEGRATED / NO DATASET**.
- **Dataset Status:** No real labeled experimental dataset (`labeled_data.csv`) collected across multiple physical fire test sessions currently exists in `data/real/`.
- **Accuracy Claims:** 0% real accuracy claimed. Metrics will only be reported once real labeled experimental datasets are collected.

### 4. Generative AI / LLM
- **Status:** **NOT IMPLEMENTED / NOT APPLICABLE**. (No LLMs are used for edge fire detection).

---

# 6. DATA PIPELINE STATUS

```text
[ REAL SENSOR (IR FLAME) ]
         │ (Analog Voltage)
         ▼
[ ESP1 NodeMCU (A0 Pin) ] ──► (USB Serial) ──► [ Python Data Logger (`flame_data_logger.py`) ] ──► [ Local CSV File ]
         │ (Wi-Fi HTTP POST)
         ▼
[ Python Ingestion Backend (`backend_server.py`) ]
         │
         ├──► [ AI Risk Engine (`ai/risk_engine.py`) ] ──► Computes Risk Score (0-100%)
         │
         ├──► [ Cloud Firestore Database (`devices/{id}`) ] (Or In-Memory Fallback)
         │
         ▼
[ Flutter App (`FirestoreDeviceRepository`) ] ──► [ Live Dashboard & Details Screen ]
```

---

# 7. MVP STATUS

| MVP Workflow | Status | Technical Reason |
| :--- | :--- | :--- |
| **WORKFLOW 1:** Real Sensors $\rightarrow$ ESP1 $\rightarrow$ Real-Time Readings $\rightarrow$ App | **WORKING** | ESP1 streams analog A0 readings over Wi-Fi POST to Python Backend; Backend updates `devices` stream; Flutter App updates UI dynamically. |
| **WORKFLOW 2:** Sensor Data $\rightarrow$ Fire-Risk Decision $\rightarrow$ Mobile Alert | **PARTIALLY WORKING** | AI Risk Engine computes risk score and fire state locally; App displays critical alert banner; Real FCM phone push notifications remain simulated. |
| **WORKFLOW 3:** Fire Detection $\rightarrow$ Direction/Angle $\rightarrow$ ESP2 $\rightarrow$ Physical Response | **WORKING** | ESP1 sweeps servo, locks angle, broadcasts ESP-NOW packet `0xAA`; ESP2 aims servo, triggers relay/pump/buzzer/LED; App displays target fire angle. |

---

# 8. CRITICAL GAPS

- **P0 (Must Fix Immediately):**
  1. Revoke and remove hardcoded Telegram Bot token and Wi-Fi credentials from legacy C++ comments.
  2. Verify ESP8266 `A0` input voltage divider so 5V/3.3V flame sensor outputs do not exceed ADC voltage limits.

- **P1 (Required for MVP Validation):**
  1. Collect real physical dataset sessions (`NORMAL_001.csv`, `FLAME_TEST_001.csv`) using `tools/flame_data_logger.py`.
  2. Add `serviceAccountKey.json` to enable persistent Cloud Firestore database sync.

- **P2 (Important After Initial MVP):**
  1. Integrate BME280 (temperature/humidity) and MQ-2 (gas/smoke) onto ESP1 hardware for multi-sensor fusion.
  2. Implement real Firebase Cloud Messaging (FCM) push notifications to mobile devices.

- **P3 (Future Commercial Features):**
  1. Train and export a lightweight C++ MicroTensorFlow / Edge ML model to execute directly on ESP32/ESP8266 microcontrollers offline.
  2. ESP2 bidirectional telemetry response status feedback.

---

# 9. WRONG-DIRECTION FEATURES (DEFER UNTIL MVP CORE WORKS)

Do **NOT** spend engineering time on these distracting features right now:
- ❌ Chatbot or LLM assistant integrations.
- ❌ Fancy PDF report export generation engines.
- ❌ Complex subscription/tier payment screens.
- ❌ Multi-building tenant authorization layers.
- ❌ Cosmetic UI gradient redesigns.

---

# 10. RECOMMENDED DEVELOPMENT ORDER

1. **Step 1:** Connect physical ESP1 hardware with IR flame sensor to USB/Wi-Fi.
2. **Step 2:** Run `python tools/flame_data_logger.py --session NORMAL_001 --condition NORMAL` to record 10 minutes of ambient room baseline.
3. **Step 3:** Run `python ai/analyze_dataset.py --input data/real/normal/NORMAL_001_<timestamp>.csv` to inspect noise floor and standard deviation.
4. **Step 4:** Safely conduct controlled test flame exposures (`FLAME_TEST_001.csv`, `FLAME_TEST_002.csv`).
5. **Step 5:** Run `python ml/train.py --data_dir data/real` to train and evaluate initial Supervised ML model on real sessions.
6. **Step 6:** Launch `python tools/backend_server.py` and verify live HTTP telemetry ingestion.
7. **Step 7:** Add your Firebase `serviceAccountKey.json` to enable cloud persistence.
8. **Step 8:** Run `flutter run -d chrome` in `D:\FireShieldAI` and observe real-time flame readings and fire state transitions.
9. **Step 9:** Wire physical BME280 temperature sensor to ESP1 for multi-sensor risk fusion.
10. **Step 10:** Enable Firebase Cloud Messaging (FCM) for real background mobile push notifications.

---

# 11. EXACT NEXT STEP

### 🎯 **DO THIS NEXT:**
> Connect your physical ESP1 board to your PC via USB, wire the IR Flame Sensor Analog Output (`AO`) to pin `A0`, upload `firmware/esp1_detection/esp1_detection.ino`, and run the Python logger to collect your first real 10-minute baseline dataset:
> ```bash
> python tools/flame_data_logger.py --session NORMAL_001 --condition NORMAL
> ```
