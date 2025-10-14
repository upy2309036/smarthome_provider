// lib/widgets/device_list.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../models/device.dart';
import 'device_card.dart';

class DeviceList extends StatelessWidget {
  const DeviceList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, provider, child) {
        // Si no hay conexión, mostrar mensaje
        if (!provider.isConnected) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bluetooth_disabled,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Not Connected',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect to your Arduino device\nto control your smart home',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navegar a pantalla de Bluetooth
                    // (lo implementaremos después)
                  },
                  icon: const Icon(Icons.bluetooth_searching),
                  label: const Text('Connect Device'),
                ),
              ],
            ),
          );
        }

        // Lista de dispositivos
        final devices = provider.devices;
        
        return RefreshIndicator(
          onRefresh: () async {
            await provider.requestSensorData();
          },
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              // Sección de LEDs
              _buildSectionHeader('LED Controls', Icons.lightbulb_outline),
              ...devices
                  .where((d) => d.type == DeviceType.led)
                  .map((device) => DeviceCard(device: device))
                  .toList(),
              
              const SizedBox(height: 16),
              
              // Sección de Servos
              _buildSectionHeader('Servo Motors', Icons.settings_input_antenna),
              ...devices
                  .where((d) => d.type == DeviceType.servo)
                  .map((device) => DeviceCard(device: device))
                  .toList(),
              
              const SizedBox(height: 16),
              
              // Información adicional
              _buildInfoCard(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(DeviceProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Device Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildInfoRow(
              'Total Devices',
              '${provider.devices.length}',
              Icons.devices,
            ),
            _buildInfoRow(
              'Active LEDs',
              '${provider.activeLEDCount} / ${provider.getLEDs().length}',
              Icons.lightbulb,
            ),
            _buildInfoRow(
              'Servo Motors',
              '${provider.getServos().length}',
              Icons.settings_input_antenna,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
