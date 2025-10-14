// lib/screens/bluetooth_devices_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothDevicesScreen extends StatefulWidget {
  const BluetoothDevicesScreen({super.key});

  @override
  State<BluetoothDevicesScreen> createState() => _BluetoothDevicesScreenState();
}

class _BluetoothDevicesScreenState extends State<BluetoothDevicesScreen> {
  final List<BluetoothDiscoveryResult> _discoveredDevices = [];
  List<BluetoothDevice> _pairedDevices = [];
  bool _isDiscovering = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndInit();
  }

  Future<void> _checkPermissionsAndInit() async {
    // Verificar y solicitar permisos
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothConnect]!.isGranted) {
      _loadPairedDevices();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth permissions required'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadPairedDevices() async {
    try {
      setState(() => _isLoading = true);
      
      List<BluetoothDevice> devices = 
          await FlutterBluetoothSerial.instance.getBondedDevices();
      
      setState(() {
        _pairedDevices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading devices: $e')),
        );
      }
    }
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isDiscovering = true;
      _discoveredDevices.clear();
    });

    try {
      FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
        setState(() {
          // Evitar duplicados
          final existingIndex = _discoveredDevices.indexWhere(
            (element) => element.device.address == result.device.address,
          );
          if (existingIndex >= 0) {
            _discoveredDevices[existingIndex] = result;
          } else {
            _discoveredDevices.add(result);
          }
        });
      }).onDone(() {
        setState(() => _isDiscovering = false);
      });
    } catch (e) {
      setState(() => _isDiscovering = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during discovery: $e')),
        );
      }
    }
  }

  Future<void> _connectToDevice(String address, String name) async {
    final provider = context.read<DeviceProvider>();

    try {
      setState(() => _isLoading = true);

      await provider.connect(address);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to $name'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Devices'),
        actions: [
          if (!_isDiscovering)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPairedDevices,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Dispositivos emparejados
                _buildSectionTitle('Paired Devices'),
                if (_pairedDevices.isEmpty)
                  _buildEmptyState('No paired devices found')
                else
                  ..._pairedDevices.map((device) => _buildDeviceTile(
                        device.name ?? 'Unknown',
                        device.address,
                        true,
                      )),

                const SizedBox(height: 24),

                // Botón de búsqueda
                ElevatedButton.icon(
                  onPressed: _isDiscovering ? null : _startDiscovery,
                  icon: Icon(_isDiscovering 
                      ? Icons.bluetooth_searching 
                      : Icons.search),
                  label: Text(_isDiscovering 
                      ? 'Searching...' 
                      : 'Discover New Devices'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),

                if (_isDiscovering) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                ],

                if (_discoveredDevices.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle('Discovered Devices'),
                  ..._discoveredDevices.map((result) => _buildDeviceTile(
                        result.device.name ?? 'Unknown',
                        result.device.address,
                        false,
                        rssi: result.rssi,
                      )),
                ],
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceTile(
    String name,
    String address,
    bool isPaired, {
    int? rssi,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPaired 
              ? Colors.blue.shade100 
              : Colors.grey.shade200,
          child: Icon(
            isPaired ? Icons.bluetooth_connected : Icons.bluetooth,
            color: isPaired ? Colors.blue.shade700 : Colors.grey.shade600,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(address),
            if (rssi != null)
              Text(
                'Signal: $rssi dBm',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _connectToDevice(address, name),
          child: const Text('Connect'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.cancelDiscovery();
    super.dispose();
  }
}
