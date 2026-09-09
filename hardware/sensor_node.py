import time
import random
import datetime

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("Please install firebase-admin: pip install firebase-admin")
    exit(1)

# ==========================================
# FireShield AI - Hardware Sensor Node
# Hardware: Raspberry Pi or ESP32 (via MicroPython)
# Sensors: DHT22, MLX90614, FLIR Lepton, DS18B20
# ==========================================

# NOTE: You must place your serviceAccountKey.json in the hardware/ directory
# and change your project ID below.
CREDENTIALS_PATH = "serviceAccountKey.json"

try:
    cred = credentials.Certificate(CREDENTIALS_PATH)
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("✅ Connected to Firebase Firestore.")
except Exception as e:
    print(f"⚠️ Warning: Could not initialize Firebase: {e}")
    print("⚠️ Running in SIMULATION ONLY mode (no cloud sync).")
    db = None

# Hardware Device ID (must match what is registered in the app)
DEVICE_ID = "device_101"

class HardwareSensors:
    def __init__(self):
        # Baseline / Normal Benchmark values
        self.ambient_temp = 25.0
        self.humidity = 50.0
        self.ir_temp = 25.0
        self.precise_temp = 25.0
        self.thermal_abnormality = False
        self.battery = 100
        print("✅ Sensors Initialized.")

    def read_dht22(self):
        """Simulate DHT22 Temperature & Humidity Sensor"""
        # In real code: import Adafruit_DHT ...
        self.ambient_temp += random.uniform(-0.5, 0.5)
        self.humidity += random.uniform(-1.0, 1.0)
        return self.ambient_temp, self.humidity

    def read_mlx90614(self):
        """Simulate MLX90614 Non-Contact IR Temperature Sensor"""
        # In real code: import board, busio, adafruit_mlx90614
        self.ir_temp = self.ambient_temp + random.uniform(-0.2, 0.2)
        return self.ir_temp

    def read_ds18b20(self):
        """Simulate DS18B20 Precise Temperature Sensor"""
        self.precise_temp = self.ambient_temp + random.uniform(-0.1, 0.1)
        return self.precise_temp

    def read_flir_lepton(self):
        """Simulate FLIR Lepton Thermal Image Analysis"""
        # In real code: Use OpenCV and thermal imaging arrays to detect hot spots.
        # Here we trigger abnormality if IR temp jumps abnormally high compared to ambient.
        if self.ir_temp > self.ambient_temp + 10.0:
            self.thermal_abnormality = True
        else:
            self.thermal_abnormality = False
        return self.thermal_abnormality

    def trigger_fire_simulation(self):
        """Simulate a rapid temperature spike (Fire Outbreak)"""
        print("\n🔥 TRIGGERING FIRE SIMULATION! TEMPERATURE SPIKE! 🔥")
        self.ambient_temp += 15.0
        self.ir_temp += 25.0 # IR detects heat source faster
        self.precise_temp += 12.0

def sync_to_cloud(sensors):
    """Pushes sensor payload to Firebase Cloud Firestore"""
    payload = {
        "ambientTemperature": round(sensors.ambient_temp, 2),
        "ambientHumidity": round(sensors.humidity, 2),
        "irTemperature": round(sensors.ir_temp, 2),
        "preciseTemperature": round(sensors.precise_temp, 2),
        "hasThermalAbnormality": sensors.thermal_abnormality,
        "batteryLevel": sensors.battery,
        "isOnline": True,
        "lastSync": datetime.datetime.utcnow().isoformat() + "Z"
    }
    
    print(f"📡 Syncing Payload: {payload}")
    
    if db:
        try:
            # Update the specific device document in Firestore
            db.collection("devices").document(DEVICE_ID).set(payload, merge=True)
            print("☁️ Cloud Sync Successful.")
        except Exception as e:
            print(f"❌ Cloud Sync Failed: {e}")

if __name__ == "__main__":
    node = HardwareSensors()
    cycle = 0
    
    try:
        while True:
            cycle += 1
            print(f"\n--- Reading Cycle {cycle} ---")
            node.read_dht22()
            node.read_mlx90614()
            node.read_ds18b20()
            node.read_flir_lepton()
            
            sync_to_cloud(node)
            
            # Simulate a fire after 5 cycles
            if cycle == 5:
                node.trigger_fire_simulation()
            
            time.sleep(5) # Send data every 5 seconds
    except KeyboardInterrupt:
        print("\nHardware Node Shutdown.")
