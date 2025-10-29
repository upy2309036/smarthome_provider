// smart_home_controller.ino
// Compatible con Arduino Uno, Mega, Nano, ESP32
// Bluetooth: HC-05, HC-06, o Bluetooth integrado (ESP32)

#include <ArduinoJson.h>
#include <DHT.h>
#define DHTTYPE DHT22

// ============ CONFIGURACIÓN DE PINES ============
// Ajusta estos pines según tu Arduino y conexiones

// LEDs (puedes usar cualquier pin digital)
const int LED1_PIN = 2;
const int LED2_PIN = 3;
const int LED3_PIN = 4;

// Servos (usa pines PWM si es posible: 3, 5, 6, 9, 10, 11)
const int SERVO1_PIN = 9;
const int SERVO2_PIN = 10;

// Sensores (si los tienen)
// DHT sensor en pin digital
const int DHT_PIN = 7;
DHT dht(DHT_PIN, DHT22);  // o DHT11

// LDR en pin analógico
const int LDR_PIN = A0;

// ============ CONFIGURACIÓN BLUETOOTH ============
// Para HC-05/HC-06 usa Serial (o SoftwareSerial si Uno)
// Para ESP32 usa SerialBT
#define BT_SERIAL Serial  // Cambia a Serial1, Serial2, o SoftwareSerial según necesites

// ============ VARIABLES GLOBALES ============
// Estados de los LEDs
bool led1State = false;
bool led2State = false;
bool led3State = false;

// Ángulos de los servos
int servo1Angle = 90;
int servo2Angle = 90;

// Buffer para comandos entrantes
String inputBuffer = "";

// Timer para lecturas de sensores
unsigned long lastSensorRead = 0;
const unsigned long SENSOR_INTERVAL = 5000; // 5 segundos

// ============ SETUP ============
void setup() {
  dht.begin();
  // Inicializar comunicación serial
  BT_SERIAL.begin(9600);  // 9600 es la velocidad típica para HC-05/HC-06
  
  // Configurar pines de LEDs como salida
  pinMode(LED1_PIN, OUTPUT);
  pinMode(LED2_PIN, OUTPUT);
  pinMode(LED3_PIN, OUTPUT);
  
  // Configurar pines de servos como salida
  pinMode(SERVO1_PIN, OUTPUT);
  pinMode(SERVO2_PIN, OUTPUT);
  
  // Apagar todos los LEDs al inicio
  digitalWrite(LED1_PIN, LOW);
  digitalWrite(LED2_PIN, LOW);
  digitalWrite(LED3_PIN, LOW);
  
  // Posición inicial de servos (90 grados - centro)
  setServoAngle(SERVO1_PIN, servo1Angle);
  setServoAngle(SERVO2_PIN, servo2Angle);
  
  // Mensaje de inicio
  delay(1000);
  sendResponse("Arduino Smart Home Ready");

}

// ============ LOOP PRINCIPAL ============
void loop() {
  // Leer comandos del Bluetooth
  if (BT_SERIAL.available()) {
    char c = BT_SERIAL.read();
    
    if (c == '\n') {
      // Comando completo recibido
      processCommand(inputBuffer);
      inputBuffer = "";
    } else {
      inputBuffer += c;
    }
  }
  
  // Enviar datos de sensores periódicamente (si los tienen conectados)
  // Descomenta esto cuando conecten los sensores

  if (millis() - lastSensorRead >= SENSOR_INTERVAL) {
    sendSensorData();
    lastSensorRead = millis();
  }

}

// ============ PROCESAMIENTO DE COMANDOS ============
void processCommand(String command) {
  // Limpiar espacios
  command.trim();
  
  if (command.length() == 0) return;
  
  // Parsear JSON
  StaticJsonDocument<256> doc;
  DeserializationError error = deserializeJson(doc, command);
  
  if (error) {
    sendResponse("Error: Invalid JSON");
    return;
  }
  
  // Extraer campos del comando
  const char* device = doc["device"];
  const char* action = doc["action"];
  
  // Procesar según el tipo de acción
  if (strcmp(action, "on") == 0) {
    handleLEDOn(device);
  }
  else if (strcmp(action, "off") == 0) {
    handleLEDOff(device);
  }
  else if (strcmp(action, "angle") == 0) {
    int angle = doc["value"];
    handleServoAngle(device, angle);
  }
  else if (strcmp(action, "read_sensors") == 0) {
    sendSensorData();
  }
  else {
    sendResponse("Error: Unknown action");
  }
}

// ============ CONTROL DE LEDs ============
void handleLEDOn(const char* device) {
  if (strcmp(device, "led1") == 0) {
    digitalWrite(LED1_PIN, HIGH);
    led1State = true;
    sendResponse("LED1 turned ON");
  }
  else if (strcmp(device, "led2") == 0) {
    digitalWrite(LED2_PIN, HIGH);
    led2State = true;
    sendResponse("LED2 turned ON");
  }
  else if (strcmp(device, "led3") == 0) {
    digitalWrite(LED3_PIN, HIGH);
    led3State = true;
    sendResponse("LED3 turned ON");
  }
  else {
    sendResponse("Error: Unknown LED");
  }
}

void handleLEDOff(const char* device) {
  if (strcmp(device, "led1") == 0) {
    digitalWrite(LED1_PIN, LOW);
    led1State = false;
    sendResponse("LED1 turned OFF");
  }
  else if (strcmp(device, "led2") == 0) {
    digitalWrite(LED2_PIN, LOW);
    led2State = false;
    sendResponse("LED2 turned OFF");
  }
  else if (strcmp(device, "led3") == 0) {
    digitalWrite(LED3_PIN, LOW);
    led3State = false;
    sendResponse("LED3 turned OFF");
  }
  else {
    sendResponse("Error: Unknown LED");
  }
}

// ============ CONTROL DE SERVOS ============
void handleServoAngle(const char* device, int angle) {
  // Validar ángulo
  if (angle < 0 || angle > 180) {
    sendResponse("Error: Invalid angle (0-180)");
    return;
  }
  
  if (strcmp(device, "servo1") == 0) {
    servo1Angle = angle;
    setServoAngle(SERVO1_PIN, angle);
    sendResponse("Servo1 moved to " + String(angle) + " degrees");
  }
  else if (strcmp(device, "servo2") == 0) {
    servo2Angle = angle;
    setServoAngle(SERVO2_PIN, angle);
    sendResponse("Servo2 moved to " + String(angle) + " degrees");
  }
  else {
    sendResponse("Error: Unknown servo");
  }
}

// Función para mover servo (sin librería Servo)
// Usa señales PWM manuales - compatible con cualquier Arduino
void setServoAngle(int pin, int angle) {
  // Convertir ángulo (0-180) a pulso (1000-2000 microsegundos)
  int pulseWidth = map(angle, 0, 180, 1000, 2000);
  
  // Enviar señal PWM por 20ms (suficiente para que el servo responda)
  for (int i = 0; i < 10; i++) {
    digitalWrite(pin, HIGH);
    delayMicroseconds(pulseWidth);
    digitalWrite(pin, LOW);
    delayMicroseconds(20000 - pulseWidth);
  }
}

// ============ LECTURA DE SENSORES ============
// Descomenta y adapta según los sensores que tengan
void sendSensorData() {
  // PLACEHOLDER - Adaptar según sus sensores reales
  
  // Si tienen DHT11/DHT22, usar biblioteca DHT:

  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();
  
  // Crear JSON con los datos
  StaticJsonDocument<256> doc;
  doc["type"] = "sensor";
  doc["temperature"] = temperature;
  doc["humidity"] = humidity;
  
  // Enviar JSON
  serializeJson(doc, BT_SERIAL);
  BT_SERIAL.println();
}

// ============ ENVIAR RESPUESTAS ============
void sendResponse(String message) {
  StaticJsonDocument<128> doc;
  doc["type"] = "response";
  doc["message"] = message;
  
  serializeJson(doc, BT_SERIAL);
  BT_SERIAL.println();
}
