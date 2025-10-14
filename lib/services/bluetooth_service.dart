// lib/services/bluetooth_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothService {
  BluetoothConnection? _connection;
  final StreamController<String> _dataController = StreamController<String>.broadcast();
  
  // Stream para escuchar datos entrantes
  Stream<String> get dataStream => _dataController.stream;
  
  bool get isConnected => _connection != null && _connection!.isConnected;
  
  // Conectar a un dispositivo Bluetooth
  Future<void> connect(String address) async {
    try {
      // Cerrar conexión previa si existe
      if (_connection != null) {
        await _connection!.close();
        _connection = null;
      }
      
      // Establecer nueva conexión
      _connection = await BluetoothConnection.toAddress(address);
      print('Conectado a: $address');
      
      // Escuchar datos entrantes
      _connection!.input!.listen(
        (data) {
          // Convertir bytes a String
          String received = utf8.decode(data);
          _dataController.add(received);
        },
        onDone: () {
          print('Conexión cerrada');
          _connection = null;
        },
        onError: (error) {
          print('Error en conexión: $error');
          _connection = null;
        },
      );
      
    } catch (e) {
      print('Error al conectar: $e');
      throw Exception('No se pudo conectar al dispositivo: $e');
    }
  }
  
  // Enviar comando al Arduino
  Future<void> sendCommand(Map<String, dynamic> command) async {
    if (_connection == null || !_connection!.isConnected) {
      throw Exception('No hay conexión Bluetooth activa');
    }
    
    try {
      // Convertir comando a JSON y agregar salto de línea
      String jsonCommand = '${jsonEncode(command)}\n';
      
      // Enviar como bytes
      _connection!.output.add(utf8.encode(jsonCommand));
      await _connection!.output.allSent;
      
      print('Comando enviado: $jsonCommand');
      
    } catch (e) {
      print('Error al enviar comando: $e');
      throw Exception('Error al enviar comando: $e');
    }
  }
  
  // Desconectar
  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
      print('Desconectado');
    }
  }
  
  // Limpiar recursos
  void dispose() {
    disconnect();
    _dataController.close();
  }
}
