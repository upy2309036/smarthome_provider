// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../widgets/connection_status_bar.dart';
import '../widgets/device_list.dart';
import '../widgets/sensor_display.dart';
import 'bluetooth_devices_screen.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Home Control'),
        actions: [
          // Botón para ir a la pantalla de conexión Bluetooth
          IconButton(
            icon: const Icon(Icons.bluetooth),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BluetoothDevicesScreen(),
                ),
              );
            },
            tooltip: 'Connect Device',
          ),
          // Botón de menú adicional
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'disconnect') {
                _handleDisconnect(context);
              } else if (value == 'refresh') {
                _handleRefresh(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh Sensors'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'disconnect',
                child: Row(
                  children: [
                    Icon(Icons.bluetooth_disabled),
                    SizedBox(width: 8),
                    Text('Disconnect'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Barra de estado de conexión
          const ConnectionStatusBar(),
          
          // Contenido principal
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: 'Devices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sensors),
            label: 'Sensors',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? _buildFloatingActionButtons()
          : null,
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const DeviceList();
      case 1:
        return const SensorDisplay();
      default:
        return const DeviceList();
    }
  }

  Widget _buildFloatingActionButtons() {
    return Consumer<DeviceProvider>(
      builder: (context, provider, child) {
        if (!provider.isConnected) return const SizedBox.shrink();
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón para encender todos
            FloatingActionButton(
              heroTag: 'allOn',
              onPressed: provider.isLoading
                  ? null
                  : () => provider.turnOnAllLEDs(),
              tooltip: 'Turn All ON',
              child: const Icon(Icons.lightbulb),
            ),
            const SizedBox(height: 10),
            // Botón para apagar todos
            FloatingActionButton(
              heroTag: 'allOff',
              onPressed: provider.isLoading
                  ? null
                  : () => provider.turnOffAllLEDs(),
              tooltip: 'Turn All OFF',
              child: const Icon(Icons.lightbulb_outline),
            ),
          ],
        );
      },
    );
  }

  // Helper to show a SnackBar safely after a build.
  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  Future<void> _handleProviderAction(
    BuildContext context,
    Future<void> Function(DeviceProvider) action,
    String successMessage,
  ) async {
    final provider = context.read<DeviceProvider>();
    if (!provider.isConnected) {
      _showSnackBar(context, 'Not connected to any device');
      return;
    }

    try {
      await action(provider);
      _showSnackBar(context, successMessage);
    } catch (e) {
      _showSnackBar(context, 'Error: $e', isError: true);
    }
  }

  void _handleDisconnect(BuildContext context) async {
    await _handleProviderAction(context, (p) => p.disconnect(), 'Disconnected successfully');
  }

  void _handleRefresh(BuildContext context) async {
    await _handleProviderAction(context, (p) => p.requestSensorData(), 'Refreshing sensor data...');
  }
}
