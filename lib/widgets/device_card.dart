// lib/widgets/device_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../models/device.dart';

class DeviceCard extends StatelessWidget {
  final SmartDevice device;

  const DeviceCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: device.isOn ? 4 : 2,
      child: device.type == DeviceType.led
          ? _buildLEDCard(context)
          : _buildServoCard(context),
    );
  }

  Widget _buildLEDCard(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: device.isOn 
            ? Colors.yellow.shade700 
            : Colors.grey.shade300,
        child: Icon(
          Icons.lightbulb,
          color: device.isOn ? Colors.white : Colors.grey.shade600,
          size: 28,
        ),
      ),
      title: Text(
        device.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        device.isOn ? 'ON' : 'OFF',
        style: TextStyle(
          color: device.isOn ? Colors.green.shade700 : Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Consumer<DeviceProvider>(
        builder: (context, provider, child) {
          return Switch(
            value: device.isOn,
            onChanged: provider.isLoading
                ? null
                : (value) async {
                    try {
                      await provider.toggleDevice(device.id);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
            activeThumbColor: Colors.yellow.shade700,
          );
        },
      ),
    );
  }

  Widget _buildServoCard(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, provider, child) {
        return ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade600,
            child: const Icon(
              Icons.settings_input_antenna,
              color: Colors.white,
              size: 28,
            ),
          ),
          title: Text(
            device.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            'Angle: ${device.angle ?? 90}°',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Slider para controlar el ángulo
                  Row(
                    children: [
                      const Text('0°'),
                      Expanded(
                        child: Slider(
                          value: (device.angle ?? 90).toDouble(),
                          min: 0,
                          max: 180,
                          divisions: 18,
                          label: '${device.angle ?? 90}°',
                          onChanged: provider.isLoading
                              ? null
                              : (value) async {
                                  try {
                                    await provider.setServoAngle(
                                      device.id,
                                      value.toInt(),
                                    );
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                        ),
                      ),
                      const Text('180°'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Botones de posición rápida
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickButton(
                        context,
                        provider,
                        '0°',
                        0,
                      ),
                      _buildQuickButton(
                        context,
                        provider,
                        '90°',
                        90,
                      ),
                      _buildQuickButton(
                        context,
                        provider,
                        '180°',
                        180,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickButton(
    BuildContext context,
    DeviceProvider provider,
    String label,
    int angle,
  ) {
    final isSelected = device.angle == angle;
    
    return ElevatedButton(
      onPressed: provider.isLoading
          ? null
          : () async {
              try {
                await provider.setServoAngle(device.id, angle);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected 
            ? Colors.blue.shade600 
            : Colors.grey.shade300,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(label),
    );
  }
}
