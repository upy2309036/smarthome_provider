// lib/models/device.dart

enum DeviceType { 
  led, 
  servo, 
  sensor 
}

class SmartDevice {
  final String id;
  final String name;
  final DeviceType type;
  bool isOn;
  int? angle; // Para servos, null para LEDs
  
  SmartDevice({
    required this.id,
    required this.name,
    required this.type,
    this.isOn = false,
    this.angle,
  });
  
  // Método para crear copia con cambios
  SmartDevice copyWith({
    String? id,
    String? name,
    DeviceType? type,
    bool? isOn,
    int? angle,
  }) {
    return SmartDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isOn: isOn ?? this.isOn,
      angle: angle ?? this.angle,
    );
  }
  
  @override
  String toString() {
    return 'SmartDevice(id: $id, name: $name, type: $type, isOn: $isOn, angle: $angle)';
  }

  // Convert a SmartDevice instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'isOn': isOn,
      'angle': angle,
    };
  }

  // Create a SmartDevice instance from a JSON map.
  factory SmartDevice.fromJson(Map<String, dynamic> json) {
    return SmartDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      type: DeviceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DeviceType.led, // Default value
      ),
      isOn: json['isOn'] as bool,
      angle: json['angle'] as int?,
    );
  }
}
