import processing.serial.*;

Serial myPort;
String data = "";
float angle = 0;
float distance = 0;
float[] distances = new float[181];

// Radar settings
int maxDistance = 40; // cm
int radarRadius;
int centerX, centerY;

void setup() {
  size(800, 500);
  smooth();
  
  centerX = width / 2;
  centerY = height - 50;
  radarRadius = height - 100;
  
  // Initialize distances array
  for (int i = 0; i <= 180; i++) {
    distances[i] = 0;
  }
  
  // Print available serial ports
  println(Serial.list());
  
  // Change COM3 to your actual port
  // Windows: "COM3", "COM4" etc
  // Mac/Linux: "/dev/ttyUSB0" or "/dev/ttyACM0"
  myPort = new Serial(this, "COM11", 115200);
  myPort.bufferUntil('\n');
}

void draw() {
  background(0);
  
  drawRadarBackground();
  drawDetectedObjects();
  drawSweepLine();
  drawBorder();
  drawInfo();
}

void drawRadarBackground() {
  // Draw distance rings
  noFill();
  strokeWeight(0.8);
  
  int[] ringDistances = {10, 20, 30, 40};
  for (int d : ringDistances) {
    float r = map(d, 0, maxDistance, 0, radarRadius);
    stroke(0, 80, 0);
    arc(centerX, centerY, r * 2, r * 2, PI, TWO_PI);
    
    // Distance labels
    fill(0, 150, 0);
    noStroke();
    textSize(11);
    textAlign(CENTER);
    text(d + " cm", centerX + r + 4, centerY - 5);
    noFill();
    stroke(0, 80, 0);
  }
  
  // Draw angle lines every 30 degrees
  stroke(0, 80, 0);
  strokeWeight(0.8);
  for (int a = 0; a <= 180; a += 30) {
    float rad = radians(a);
    float x = centerX - radarRadius * cos(rad);
    float y = centerY - radarRadius * sin(rad);
    line(centerX, centerY, x, y);
    
    // Angle labels
    fill(0, 150, 0);
    noStroke();
    textSize(11);
    textAlign(CENTER);
    float lx = centerX - (radarRadius + 20) * cos(rad);
    float ly = centerY - (radarRadius + 20) * sin(rad);
    text(a + "°", lx, ly);
    noFill();
    stroke(0, 80, 0);
  }
}

void drawDetectedObjects() {
  // Draw fading dots for detected objects
  for (int a = 0; a <= 180; a++) {
    if (distances[a] > 0 && distances[a] < maxDistance) {
      float r = map(distances[a], 0, maxDistance, 0, radarRadius);
      float rad = radians(a);
      float x = centerX - r * cos(rad);
      float y = centerY - r * sin(rad);
      
      // Fade based on angle distance from current sweep
      float angleDiff = abs(a - angle);
      float alpha = map(angleDiff, 0, 60, 255, 30);
      alpha = constrain(alpha, 30, 255);
      
      // Color based on distance (green = far, red = close)
      float distRatio = distances[a] / maxDistance;
      stroke(255 * (1 - distRatio), 255 * distRatio, 0, alpha);
      strokeWeight(3);
      point(x, y);
      
      // Draw small circle on detected object
      noFill();
      strokeWeight(1);
      stroke(255 * (1 - distRatio), 255 * distRatio, 0, alpha * 0.6);
      ellipse(x, y, 8, 8);
    }
  }
}

void drawSweepLine() {
  // Draw glowing sweep line
  float rad = radians(angle);
  
  // Outer glow
  for (int i = 5; i >= 1; i--) {
    stroke(0, 255, 0, 20 * i);
    strokeWeight(i * 1.5);
    float x = centerX - radarRadius * cos(rad);
    float y = centerY - radarRadius * sin(rad);
    line(centerX, centerY, x, y);
  }
  
  // Core line
  stroke(0, 255, 0, 200);
  strokeWeight(1.5);
  float x = centerX - radarRadius * cos(rad);
  float y = centerY - radarRadius * sin(rad);
  line(centerX, centerY, x, y);
  
  // Sweep trail (fading behind the line)
  for (int i = 1; i <= 20; i++) {
    float trailAngle = angle - i * 2;
    if (trailAngle < 0) trailAngle = 0;
    float trailRad = radians(trailAngle);
    float alpha = map(i, 0, 20, 150, 0);
    stroke(0, 200, 0, alpha);
    strokeWeight(1);
    float tx = centerX - radarRadius * cos(trailRad);
    float ty = centerY - radarRadius * sin(trailRad);
    line(centerX, centerY, tx, ty);
  }
}

void drawBorder() {
  // Outer arc border
  noFill();
  stroke(0, 200, 0);
  strokeWeight(2);
  arc(centerX, centerY, radarRadius * 2, radarRadius * 2, PI, TWO_PI);
  
  // Base line
  line(centerX - radarRadius, centerY, centerX + radarRadius, centerY);
  
  // Center dot
  fill(0, 255, 0);
  noStroke();
  ellipse(centerX, centerY, 6, 6);
}

void drawInfo() {
  // Info panel
  fill(0, 200, 0);
  noStroke();
  textSize(13);
  textAlign(LEFT);
  
  text("Angle   : " + int(angle) + "°", 20, 30);
  text("Distance: " + int(distance) + " cm", 20, 50);
  
  if (distance < maxDistance && distance > 0) {
    fill(255, 50, 50);
    text("OBJECT DETECTED", 20, 80);
  } else {
    fill(0, 200, 0);
    text("No object", 20, 80);
  }
  
  // Title
  fill(0, 255, 0);
  textSize(18);
  textAlign(CENTER);
  text("ESP32 RADAR", width / 2, 30);
}

void serialEvent(Serial myPort) {
  data = myPort.readStringUntil('\n');
  if (data != null) {
    data = trim(data);
    String[] values = split(data, ',');
    if (values.length == 2) {
      try {
        angle = float(values[0]);
        distance = float(values[1]);
        if (angle >= 0 && angle <= 180) {
          distances[int(angle)] = distance;
        }
      } catch (Exception e) {
        println("Parse error: " + e.getMessage());
      }
    }
  }
}
