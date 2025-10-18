// lib/widgets/sensor_display.dart (SIN FONT_AWESOME)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../models/sensor_data.dart';

class SensorDisplay extends StatelessWidget {
  const SensorDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, provider, child) {
        final SensorData? data = provider.currentSensorData;
        final bool isConnected = provider.isConnected;
        
        // --- 1. Estado Desconectado o Sin Datos ---
        if (!isConnected || data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isConnected ? Icons.sensors_off : Icons.bluetooth_disabled,
                  size: 80,
                  color: isConnected ? Colors.orange.shade400 : Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  isConnected ? 'Waiting for Sensor Data' : 'Bluetooth Disconnected',
                  style: TextStyle(fontSize: 20, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isConnected 
                      ? 'The Arduino must send the first data packet.'
                      : 'Please connect to your HC-05 module.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                
                // Botón para pedir datos (útil si la lectura no es automática)
                ElevatedButton.icon(
                  onPressed: provider.isLoading
                      ? null
                      : () => provider.requestSensorData(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Request Sensor Update'),
                ),
              ],
            ),
          );
        }

        // --- 2. Estado Conectado y con Datos ---
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSensorCard(
                context,
                // Ícono de Material para Temperatura (ej: Termómetro)
                icon: Icons.thermostat, 
                label: 'Temperature (DHT)',
                value: '${data.temperature.toStringAsFixed(1)} °C',
                color: Colors.orange,
              ),
              _buildSensorCard(
                context,
                // Ícono de Material para Humedad (ej: Gota de agua/Gotas)
                icon: Icons.water_drop, 
                label: 'Humidity (DHT)',
                value: '${data.humidity.toStringAsFixed(1)} %',
                color: Colors.blue,
              ),
              
              const SizedBox(height: 30),
              Text(
                'Last Update: ${data.timestamp.toString().substring(11, 19)}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Widget helper para construir las tarjetas de forma consistente
  Widget _buildSensorCard(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Usamos Icon en lugar de FaIcon
            Icon(icon, size: 36, color: color), 
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}