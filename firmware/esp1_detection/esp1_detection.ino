#include <Arduino.h>
#include <Servo.h>
#include "config.h"

Servo scanServo;

int scanAngle = 0;
int scanDirection = 1;
unsigned long lastSampleTime = 0;

void setup() {
  Serial.begin(115200);
  delay(200);

  pinMode(FLAME_DIGITAL_PIN, INPUT);
  
  scanServo.attach(SERVO_PIN);
  scanServo.write(90);
  scanAngle = 90;
  delay(300);

  // Print initial CSV Header to Serial
  Serial.println("timestamp_ms,device_id,room_id,flame_raw,flame_digital,servo_angle");
}

void loop() {
  unsigned long currentTime = millis();

  if (currentTime - lastSampleTime >= SAMPLE_INTERVAL_MS) {
    lastSampleTime = currentTime;

    // Read Sensors
    int flameRaw = analogRead(FLAME_ANALOG_PIN);
    int flameDigital = digitalRead(FLAME_DIGITAL_PIN);

    // Output Machine-Readable CSV line over Serial
    Serial.print(currentTime);
    Serial.print(",");
    Serial.print(DEVICE_ID);
    Serial.print(",");
    Serial.print(ROOM_ID);
    Serial.print(",");
    Serial.print(flameRaw);
    Serial.print(",");
    Serial.print(flameDigital);
    Serial.print(",");
    Serial.println(scanAngle);

    // Increment scanning angle
    scanAngle += scanDirection * 5;
    if (scanAngle >= 180) {
      scanAngle = 180;
      scanDirection = -1;
    } else if (scanAngle <= 0) {
      scanAngle = 0;
      scanDirection = 1;
    }
    scanServo.write(scanAngle);
  }
}
