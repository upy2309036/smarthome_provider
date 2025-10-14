// lib/models/sensor_data.dart

class SensorData {
  final double temperature;
  final double humidity;
  final DateTime timestamp;
  
  SensorData({
    required this.temperature,
    required this.humidity,
    required this.timestamp,
  });
  
  // Constructor para crear desde JSON (datos del Arduino)
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] ?? 0).toDouble(),
      humidity: (json['humidity'] ?? 0).toDouble(),
      timestamp: DateTime.now(),
    );
  }
  
  // Convertir a JSON (para guardar en base de datos)
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  @override
  String toString() {
    return 'SensorData(temp: ${temperature.toStringAsFixed(1)}°C, humidity: ${humidity.toStringAsFixed(1)}%)';
  }
}
