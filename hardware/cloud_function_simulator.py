import time

try:
    import firebase_admin
    from firebase_admin import credentials, firestore, messaging
except ImportError:
    print("Please install firebase-admin: pip install firebase-admin")
    exit(1)

# ==========================================
# FireShield AI - Cloud Function Simulator
# Simulates the backend "AI Analysis & Benchmark Compare"
# Triggers an FCM Push Notification to the user's app on Fire
# ==========================================

CREDENTIALS_PATH = "serviceAccountKey.json"

try:
    cred = credentials.Certificate(CREDENTIALS_PATH)
    firebase_admin.initialize_app(cred, name="cloud_simulator")
    db = firestore.client(app=firebase_admin.get_app("cloud_simulator"))
    print("✅ Connected to Firebase Cloud Firestore.")
except Exception as e:
    print(f"⚠️ Warning: Could not initialize Firebase: {e}")
    print("⚠️ Running in SIMULATION ONLY mode (no cloud sync).")
    db = None

# The FCM Token of the user's mobile device (obtained from Flutter app)
USER_FCM_TOKEN = "SIMULATED_FCM_TOKEN_OR_REAL_TOKEN"

def send_push_notification(device_id, ir_temp, ambient_temp):
    """Sends a high-priority push notification via Firebase Cloud Messaging"""
    print(f"\n🚨 [CRITICAL ALERT] 🚨")
    print(f"Abnormal pattern detected on {device_id}!")
    print(f"IR Temp: {ir_temp}°C vs Ambient: {ambient_temp}°C")
    
    if db and USER_FCM_TOKEN != "SIMULATED_FCM_TOKEN_OR_REAL_TOKEN":
        message = messaging.Message(
            notification=messaging.Notification(
                title="🔥 FIRE ALERT DETECTED 🔥",
                body=f"Abnormal thermal spike on {device_id}. IR Temp: {ir_temp}°C. Evacuate immediately!",
            ),
            data={"device_id": device_id, "type": "fire_alert"},
            token=USER_FCM_TOKEN,
        )
        try:
            response = messaging.send(message, app=firebase_admin.get_app("cloud_simulator"))
            print(f"✅ Push Notification sent successfully: {response}")
        except Exception as e:
            print(f"❌ Failed to send Push Notification: {e}")
    else:
        print("📲 (Simulated) Push Notification sent to user's phone.")

def analyze_device_data(doc_snapshot, changes, read_time):
    """Callback function triggered when a device document is updated in Firestore"""
    for doc in doc_snapshot:
        data = doc.to_dict()
        device_id = doc.id
        
        ambient = data.get("ambientTemperature", 25.0)
        ir = data.get("irTemperature", 25.0)
        thermal_abnormal = data.get("hasThermalAbnormality", False)
        
        # BENCHMARK COMPARISON (As per Patent Slide 4)
        # If IR temperature is significantly higher than ambient, or thermal image is abnormal
        if thermal_abnormal or ir > ambient + 10.0:
            send_push_notification(device_id, ir, ambient)

if __name__ == "__main__":
    print("☁️ Cloud Function Simulator Started. Listening for sensor data...")
    if db:
        # Listen for real-time updates on the 'devices' collection
        doc_watch = db.collection("devices").on_snapshot(analyze_device_data)
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("\nShutting down Cloud Simulator.")
    else:
        # Run a local simulation loop
        try:
            print("Running simulated data check...")
            time.sleep(5)
            # Simulate receiving abnormal data
            send_push_notification("device_101", 65.0, 40.0)
        except KeyboardInterrupt:
            pass
