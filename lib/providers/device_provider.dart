// lib/providers/device_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/device.dart';
import '../models/sensor_data.dart';
import '../services/bluetooth_service.dart';

class DeviceProvider extends ChangeNotifier {
  // Servicio de Bluetooth
  final BluetoothService _bluetoothService;
  
  // Estado privado
  List<SmartDevice> _devices = [];
  SensorData? _currentSensorData;
  bool _isConnected = false;
  String _statusMessage = 'Desconectado';
  bool _isLoading = false;
  
  // Constructor
  DeviceProvider(this._bluetoothService) {
    _listenToBluetoothData();
  }
  
  // Getters públicos (solo lectura)
  List<SmartDevice> get devices => List.unmodifiable(_devices);
  SensorData? get currentSensorData => _currentSensorData;
  bool get isConnected => _isConnected;
  String get statusMessage => _statusMessage;
  bool get isLoading => _isLoading;

  /// Updates the devices based on a profile's settings.
  void applyProfileSettings(List<SmartDevice> deviceSettings) {
    // Create deep copies to prevent modifying the original profile settings
    _devices = deviceSettings.map((d) => d.copyWith()).toList();
    notifyListeners();
  }
  // lib/providers/device_provider.dart

// ... (código existente) ...

// ============ DEFINICIÓN DE PERFILES ============
// Estructura: 'Perfil': [{'device': ID, 'type': 'led'/'servo', 'value': ESTADO/ANGULO}]
static const Map<String, List<Map<String, dynamic>>> _userProfiles = {
  'Mamá': [
    // LED: Solo el de la habitación encendido
    {'device': 'led1', 'type': DeviceType.led, 'value': true},  // Living Room OFF
    {'device': 'led2', 'type': DeviceType.led, 'value': true}, // Bedroom ON
    {'device': 'led3', 'type': DeviceType.led, 'value': false}, // Kitchen OFF
    // SERVO: Cortinas arriba (Ángulo 180)
    {'device': 'servo1', 'type': DeviceType.servo, 'value': 180}, // Window Blind (Abierto)
    {'device': 'servo2', 'type': DeviceType.servo, 'value': 0},  // Door Lock (Cerrado)
  ],
  'Papá': [
    // LED: Cocina y Salón encendidos
    {'device': 'led1', 'type': DeviceType.led, 'value': true},
    {'device': 'led2', 'type': DeviceType.led, 'value': false},
    {'device': 'led3', 'type': DeviceType.led, 'value': true},
    // SERVO: Cortinas a mitad (Ángulo 90)
    {'device': 'servo1', 'type': DeviceType.servo, 'value': 90},
    {'device': 'servo2', 'type': DeviceType.servo, 'value': 0}, 
  ],
  'Hijo': [
    // LED: Todo apagado
    {'device': 'led1', 'type': DeviceType.led, 'value': false},
    {'device': 'led2', 'type': DeviceType.led, 'value': false},
    {'device': 'led3', 'type': DeviceType.led, 'value': false},
    // SERVO: Cortinas abajo (Ángulo 0)
    {'device': 'servo1', 'type': DeviceType.servo, 'value': 0}, // Window Blind (Cerrado)
    {'device': 'servo2', 'type': DeviceType.servo, 'value': 90}, // Door Lock (Abierto para el hijo)
  ],
  
};

// Getter para la UI
Map<String, List<Map<String, dynamic>>> get userProfiles => _userProfiles;
// lib/providers/device_provider.dart

// ... (código existente de control de servos/LEDs) ...

// ============ FUNCIÓN NUEVA: APLICAR PERFIL ============
Future<void> applyProfile(String profileName) async {
  if (!_userProfiles.containsKey(profileName)) {
    _statusMessage = 'Error: Perfil "$profileName" no existe.';
    notifyListeners();
    return;
  }
  
  _isLoading = true;
  _statusMessage = 'Applying $profileName profile...';
  notifyListeners();
  
  try {
    final actions = _userProfiles[profileName]!;
    
    for (var action in actions) {
      final deviceId = action['device'] as String;
      final type = action['type'] as DeviceType;
      final value = action['value'];
      
      Map<String, dynamic> command = {};
      
      // 1. Construir el comando JSON para el Arduino
      if (type == DeviceType.led) {
        command = {
          'device': deviceId,
          'action': value ? 'on' : 'off'
        };
      } else if (type == DeviceType.servo) {
        command = {
          'device': deviceId,
          'action': 'angle',
          'value': value
        };
      }
      
      // 2. Enviar comando
      await _bluetoothService.sendCommand(command);
      
      // 3. Actualizar el estado localmente (para la UI)
      final deviceIndex = _devices.indexWhere((d) => d.id == deviceId);
      if (deviceIndex != -1) {
          final oldDevice = _devices[deviceIndex];
          if (type == DeviceType.led) {
             _devices[deviceIndex] = oldDevice.copyWith(isOn: value as bool);
          } else if (type == DeviceType.servo) {
             _devices[deviceIndex] = oldDevice.copyWith(angle: value as int);
          }
      }

      // Pausa breve para evitar saturar el HC-05
      await Future.delayed(const Duration(milliseconds: 50)); 
    }
    
    _statusMessage = 'Profile $profileName applied successfully.';
    _isLoading = false;
    notifyListeners();
    
  } catch (e) {
    _statusMessage = 'Error applying profile: ${e.toString()}';
    _isLoading = false;
    notifyListeners();
    rethrow;
  }
}
// Encender/Apagar LED
  Future<void> toggleDevice(String deviceId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Buscar el dispositivo
      final deviceIndex = _devices.indexWhere((d) => d.id == deviceId);
      if (deviceIndex == -1) {
        throw Exception('Dispositivo no encontrado');
      }
      
      final device = _devices[deviceIndex];
      
      // Cambiar estado
      device.isOn = !device.isOn;
      
      // Preparar comando para Arduino
      final command = {
        'device': deviceId,
        'action': device.isOn ? 'on' : 'off'
      };
      
      // Enviar comando
      await _bluetoothService.sendCommand(command);
      
      // Actualizar mensaje de estado
      _statusMessage = '${device.name} turned ${device.isOn ? "on" : "off"}';
      
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      _statusMessage = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Controlar ángulo del servo
  Future<void> setServoAngle(String deviceId, int angle) async {
    try {
      // Validar ángulo (0-180 grados)
      if (angle < 0 || angle > 180) {
        _statusMessage = 'Ángulo inválido. Debe ser 0-180';
        notifyListeners();
        return;
      }
      
      _isLoading = true;
      notifyListeners();
      
      // Buscar el servo
      final deviceIndex = _devices.indexWhere((d) => d.id == deviceId);
      if (deviceIndex == -1) {
        throw Exception('Servo no encontrado');
      }
      
      final device = _devices[deviceIndex];
      
      // Actualizar ángulo
      device.angle = angle;
      
      // Preparar comando
      final command = {
        'device': deviceId,
        'action': 'angle',
        'value': angle
      };
      
      // Enviar comando
      await _bluetoothService.sendCommand(command);
      
      _statusMessage = '${device.name} moved to $angle°';
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      _statusMessage = 'Error controlling servo: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Encender todos los LEDs
  Future<void> turnOnAllLEDs() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      for (var device in _devices) {
        if (device.type == DeviceType.led && !device.isOn) {
          await toggleDevice(device.id);
          // Pequeña pausa entre comandos
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      
      _statusMessage = 'All LEDs turned on';
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      _statusMessage = 'Error turning on LEDs: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Apagar todos los LEDs
  Future<void> turnOffAllLEDs() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      for (var device in _devices) {
        if (device.type == DeviceType.led && device.isOn) {
          await toggleDevice(device.id);
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      
      _statusMessage = 'All LEDs turned off';
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      _statusMessage = 'Error turning off LEDs: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
// Escuchar datos que llegan del Arduino vía Bluetooth
  void _listenToBluetoothData() {
    _bluetoothService.dataStream.listen(
      (data) {
        try {
          // Limpiar datos (puede venir con caracteres extra)
          String cleanData = data.trim();
          
          // Intentar parsear JSON
          final jsonData = jsonDecode(cleanData);
          
          // Verificar si son datos de sensores
          if (jsonData['type'] == 'sensor') {
            _currentSensorData = SensorData.fromJson(jsonData);
            _statusMessage = 'Sensor data updated';
            notifyListeners();
          }
          
          // Verificar si es confirmación de comando
          else if (jsonData['type'] == 'response') {
            _statusMessage = jsonData['message'] ?? 'Command executed';
            notifyListeners();
          }
          
        } catch (e) {
          print('Error parsing Bluetooth data: $e');
          print('Raw data received: $data');
          // No actualizar UI si hay error de parsing
        }
      },
      onError: (error) {
        print('Error in Bluetooth stream: $error');
        _statusMessage = 'Bluetooth communication error';
        notifyListeners();
      },
    );
  }
  
  // Solicitar lecturas de sensores al Arduino
  Future<void> requestSensorData() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final command = {
        'action': 'read_sensors'
      };
      
      await _bluetoothService.sendCommand(command);
      
      _statusMessage = 'Requesting sensor data...';
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      _statusMessage = 'Error requesting sensor data: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Obtener dispositivo por ID
  SmartDevice? getDeviceById(String deviceId) {
    try {
      return _devices.firstWhere((device) => device.id == deviceId);
    } catch (e) {
      return null;
    }
  }
  
  // Obtener todos los LEDs
  List<SmartDevice> getLEDs() {
    return _devices.where((d) => d.type == DeviceType.led).toList();
  }
  
  // Obtener todos los servos
  List<SmartDevice> getServos() {
    return _devices.where((d) => d.type == DeviceType.servo).toList();
  }
  
  // Verificar si hay algún LED encendido
  bool get hasAnyLEDOn {
    return _devices.any((d) => d.type == DeviceType.led && d.isOn);
  }
  
  // Contar LEDs encendidos
  int get activeLEDCount {
    return _devices.where((d) => d.type == DeviceType.led && d.isOn).length;
  }
// Conectar al Arduino vía Bluetooth
  Future<void> connect(String address) async {
    try {
      _isLoading = true;
      _statusMessage = 'Connecting...';
      notifyListeners();
      
      // Intentar conectar
      await _bluetoothService.connect(address);
      
      // Actualizar estado
      _isConnected = true;
      _statusMessage = 'Connected successfully';
      _isLoading = false;
      notifyListeners();
      
      // Solicitar datos iniciales de sensores después de conectar
      await Future.delayed(const Duration(milliseconds: 500));
      await requestSensorData();
      
    } catch (e) {
      _isConnected = false;
      _statusMessage = 'Connection failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Desconectar del Arduino
  Future<void> disconnect() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _bluetoothService.disconnect();
      
      _isConnected = false;
      _statusMessage = 'Disconnected';
      _currentSensorData = null;
      _devices.clear(); // Clear devices on disconnect
      
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      _statusMessage = 'Error disconnecting: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Verificar estado de conexión Bluetooth
  Future<void> checkConnection() async {
    _isConnected = _bluetoothService.isConnected;
    
    if (!_isConnected) {
      _statusMessage = 'Connection lost';
      _currentSensorData = null;
    }
    
    notifyListeners();
  }
  
  // Reintentar conexión
  Future<void> reconnect(String address) async {
    try {
      _statusMessage = 'Reconnecting...';
      notifyListeners();
      
      await disconnect();
      await Future.delayed(const Duration(seconds: 1));
      await connect(address);
      
    } catch (e) {
      _statusMessage = 'Reconnection failed: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }
  
  // Limpiar recursos cuando el Provider se destruye
  @override
  void dispose() {
    _bluetoothService.dispose();
    super.dispose();
  }
}
