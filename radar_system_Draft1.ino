#include <ESP32Servo.h>

Servo radarServo;

const int trigPin = 13;
const int echoPin = 12;
const int servoPin = 14;

long duration;
int distance;
int angle;

void setup() {
  Serial.begin(115200);
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  radarServo.attach(servoPin);
}

int getDistance() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);

  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  duration = pulseIn(echoPin, HIGH);
  distance = duration * 0.034 / 2;

  return distance;
}

void loop() {
  // Sweep 0 to 180
  for (angle = 0; angle <= 180; angle += 2) {
    radarServo.write(angle);
    delay(30);
    distance = getDistance();
    Serial.print(angle);
    Serial.print(",");
    Serial.println(distance);
  }

  // Sweep 180 to 0
  for (angle = 180; angle >= 0; angle -= 2) {
    radarServo.write(angle);
    delay(30);
    distance = getDistance();
    Serial.print(angle);
    Serial.print(",");
    Serial.println(distance);
  }
}
