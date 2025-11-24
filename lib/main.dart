import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:neo_bluetooth_module/ble/ble.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE JSON Module Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BleDemoPage(),
    );
  }
}

class BleDemoPage extends StatefulWidget {
  const BleDemoPage({super.key});

  @override
  State<BleDemoPage> createState() => _BleDemoPageState();
}

class _BleDemoPageState extends State<BleDemoPage> {
  final BleManager _manager = BleManager();
  final List<BleDeviceInfo> _devices = [];
  BleDeviceConnection? _connection;
  BleGattInfo? _gattInfo;
  BleJsonConnection? _jsonConnection;
  GattServiceInfo? _selectedService;
  GattCharInfo? _selectedCharacteristic;
  final TextEditingController _jsonController = TextEditingController();
  bool _isScanning = false;
  String _statusMessage = 'Ready to scan';

  @override
  void initState() {
    super.initState();
    _jsonController.text = '{"command": "setAnimation", "name": "wave", "speed": 0.7}';
  }

  @override
  void dispose() {
    _manager.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _devices.clear();
      _statusMessage = 'Scanning...';
    });

    try {
      await _manager.scan();
      _manager.scanResults.listen((device) {
        if (!mounted) return;
        setState(() {
          if (!_devices.any((d) => d.id == device.id)) {
            _devices.add(device);
          }
        });
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isScanning = false;
      });
    }
  }

  Future<void> _stopScan() async {
    await _manager.stopScan();
    setState(() {
      _isScanning = false;
      _statusMessage = 'Scan stopped';
    });
  }

  Future<void> _connectToDevice(BleDeviceInfo device) async {
    setState(() {
      _statusMessage = 'Connecting...';
    });

    try {
      final connection = await _manager.connect(device);
      
      // Set connection immediately so UI can show it
      if (mounted) {
        setState(() {
          _connection = connection;
          _statusMessage = 'Connected';
        });
      }
      
      // Set up listener for connection state changes
      connection.connectionState.listen((state) {
        if (!mounted) return;
        setState(() {
          switch (state) {
            case BleConnectionState.connecting:
              _statusMessage = 'Connecting...';
              break;
            case BleConnectionState.connected:
              _statusMessage = 'Connected';
              // Ensure connection is always set when connected
              _connection = connection;
              break;
            case BleConnectionState.disconnected:
              _statusMessage = 'Disconnected';
              _connection = null;
              _gattInfo = null;
              _jsonConnection = null;
              break;
            case BleConnectionState.error:
              _statusMessage = 'Connection error';
              break;
          }
        });
      });
      
      // Force a rebuild to ensure UI updates
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              // Trigger rebuild to ensure Connected Device section appears
            });
          }
        });
      }

      await _discoverGatt(connection);
    } catch (e) {
      setState(() {
        _statusMessage = 'Connection failed: $e';
      });
    }
  }

  Future<void> _discoverGatt(BleDeviceConnection connection) async {
    setState(() {
      _statusMessage = 'Discovering GATT...';
    });

    try {
      final gatt = await _manager.discoverGatt(connection);
      setState(() {
        _gattInfo = gatt;
        _statusMessage = 'GATT discovered: ${gatt.services.length} services';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'GATT discovery failed: $e';
      });
    }
  }

  Future<void> _selectCharacteristic(GattServiceInfo service, GattCharInfo characteristic) async {
    if (!characteristic.canWrite) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Characteristic does not support write')),
      );
      return;
    }

    try {
      final jsonConn = await _manager.createJsonConnection(
        _connection!,
        service.uuid,
        characteristic.uuid,
      );

      setState(() {
        _selectedService = service;
        _selectedCharacteristic = characteristic;
        _jsonConnection = jsonConn;
        _statusMessage = 'Ready to send JSON';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _sendJson() async {
    if (_jsonConnection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No characteristic selected')),
      );
      return;
    }

    try {
      final jsonString = _jsonController.text.trim();
      if (jsonString.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter JSON data')),
        );
        return;
      }

      // Try to parse as JSON first
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        await _jsonConnection!.sendJson(json);
      } catch (e) {
        // If parsing fails, send as string
        await _jsonConnection!.sendJsonString(jsonString);
      }

      setState(() {
        _statusMessage = 'JSON sent successfully';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JSON sent successfully')),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Send failed: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e')),
      );
    }
  }

  Future<void> _disconnect() async {
    if (_connection != null) {
      await _manager.disconnect(_connection!);
      setState(() {
        _connection = null;
        _gattInfo = null;
        _jsonConnection = null;
        _selectedService = null;
        _selectedCharacteristic = null;
        _statusMessage = 'Disconnected';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE JSON Module Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Status: $_statusMessage',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Scan controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isScanning ? null : _startScan,
                    child: const Text('Start Scan'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isScanning ? _stopScan : null,
                    child: const Text('Stop Scan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Device list
            if (_devices.isNotEmpty) ...[
              Text(
                'Found Devices (${_devices.length}):',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...(_devices.map((device) => Card(
                    child: ListTile(
                      title: Text(device.name ?? 'Unknown Device'),
                      subtitle: Text('ID: ${device.id}\nRSSI: ${device.rssi} dBm'),
                      trailing: _connection?.deviceInfo.id == device.id
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: _connection == null
                          ? () => _connectToDevice(device)
                          : null,
                    ),
                  ))),
              const SizedBox(height: 16),
            ],

            // Connection info
            if (_connection != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connected Device',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Name: ${_connection!.deviceInfo.name ?? "Unknown"}'),
                      Text('ID: ${_connection!.deviceInfo.id}'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _disconnect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Disconnect'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // GATT services
            if (_gattInfo != null) ...[
              Text(
                'GATT Services (${_gattInfo!.services.length}):',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...(_gattInfo!.services.map((service) => Card(
                    child: ExpansionTile(
                      title: Text('Service: ${service.uuid}'),
                      subtitle: Text(
                          '${service.characteristics.length} characteristics'),
                      children: [
                        ...(service.characteristics.map((char) => ListTile(
                              title: Text('Characteristic: ${char.uuid}'),
                              subtitle: Text(
                                  'Read: ${char.canRead}, Write: ${char.canWrite}, Notify: ${char.canNotify}'),
                              trailing: char.canWrite
                                  ? ElevatedButton(
                                      onPressed: () =>
                                          _selectCharacteristic(service, char),
                                      child: const Text('Select'),
                                    )
                                  : null,
                            ))),
                      ],
                    ),
                  ))),
              const SizedBox(height: 16),
            ],

            // Selected characteristic
            if (_selectedCharacteristic != null) ...[
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Characteristic',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                          'Service: ${_selectedService!.uuid}'),
                      Text(
                          'Characteristic: ${_selectedCharacteristic!.uuid}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // JSON input
            if (_jsonConnection != null) ...[
              Text(
                'Send JSON:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _jsonController,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter JSON data',
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _sendJson,
                child: const Text('Send JSON'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
