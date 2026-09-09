#ifndef CONFIG_H
#define CONFIG_H

// =====================================================
// DEVICE CONFIGURATION
// =====================================================

#define DEVICE_ID "ESP1"
#define ROOM_ID   "ROOM_1"

// =====================================================
// HARDWARE PINS
// =====================================================

#define FLAME_ANALOG_PIN  A0     // Analog pin for raw continuous AI signal
#define FLAME_DIGITAL_PIN 14     // GPIO14 / D5 for digital threshold read
#define SERVO_PIN         12     // GPIO12 / D6 for scanning servo motor

// =====================================================
// SAMPLING CONFIGURATION
// =====================================================

// Interval between data samples in milliseconds (default: 500ms = 2 Hz)
#define SAMPLE_INTERVAL_MS 500

#endif // CONFIG_H
