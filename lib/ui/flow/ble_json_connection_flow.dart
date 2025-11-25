import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:neo_bluetooth_module/ble/ble.dart';
import '../ui.dart';

/// A complete, reusable BLE JSON connection flow widget
/// 
/// This widget manages the entire BLE connection workflow:
/// - Scanning for devices
/// - Connecting to a device
/// - Discovering GATT services
/// - Selecting a characteristic
/// - Sending JSON data
/// 
/// Can be used as a standalone page or embedded widget.
class BleJsonConnectionFlow extends StatefulWidget {
  /// Callback when flow completes successfully
  final void Function(BleJsonConnectionResult)? onComplete;

  /// Callback when user cancels the flow
  final VoidCallback? onCancel;

  /// Pre-filled JSON text
  final String? initialJsonText;

  /// App bar title
  final String appBarTitle;

  /// Whether to automatically discover GATT after connection
  final bool autoDiscoverGatt;

  const BleJsonConnectionFlow({
    super.key,
    this.onComplete,
    this.onCancel,
    this.initialJsonText,
    this.appBarTitle = 'BLE Connection',
    this.autoDiscoverGatt = true,
  });

  /// Helper method to navigate to the flow and get result
  static Future<BleJsonConnectionResult?> navigate(
    BuildContext context, {
    String? initialJsonText,
    String appBarTitle = 'BLE Connection',
  }) async {
    BleJsonConnectionResult? result;

    await Navigator.push<BleJsonConnectionResult>(
      context,
      MaterialPageRoute(
        builder: (_) => BleJsonConnectionFlow(
          appBarTitle: appBarTitle,
          initialJsonText: initialJsonText,
          onComplete: (r) {
            result = r;
            Navigator.of(context).pop(r);
          },
          onCancel: () {
            Navigator.of(context).pop(BleJsonConnectionResult.cancelled());
          },
        ),
      ),
    );

    return result;
  }

  @override
  State<BleJsonConnectionFlow> createState() => _BleJsonConnectionFlowState();
}

class _BleJsonConnectionFlowState extends State<BleJsonConnectionFlow> {
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
    _jsonController.text = widget.initialJsonText ??
        '{"command": "setAnimation", "name": "wave", "speed": 0.7}';
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

      if (widget.autoDiscoverGatt) {
        await _discoverGatt(connection);
      }
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

  Future<void> _selectCharacteristic(
      GattServiceInfo service, GattCharInfo characteristic) async {
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

      // Call onComplete with success result
      if (widget.onComplete != null && _jsonConnection != null) {
        widget.onComplete!(BleJsonConnectionResult.success(
          jsonConnection: _jsonConnection!,
          deviceConnection: _connection!,
          selectedService: _selectedService!,
          selectedCharacteristic: _selectedCharacteristic!,
        ));
      }
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

  void _handleBack() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      // Default: return cancelled result
      if (widget.onComplete != null) {
        widget.onComplete!(BleJsonConnectionResult.cancelled());
      }
      Navigator.of(context).pop(BleJsonConnectionResult.cancelled());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        appBar: BleAppBar(
          title: widget.appBarTitle,
          actions: [
            if (_jsonConnection != null)
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'Done',
                onPressed: () {
                  if (widget.onComplete != null && _jsonConnection != null) {
                    widget.onComplete!(BleJsonConnectionResult.success(
                      jsonConnection: _jsonConnection!,
                      deviceConnection: _connection!,
                      selectedService: _selectedService!,
                      selectedCharacteristic: _selectedCharacteristic!,
                    ));
                  }
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scan section
              BleScanSection(
                statusMessage: _statusMessage,
                isScanning: _isScanning,
                onStartScan: _startScan,
                onStopScan: _stopScan,
              ),
              const SizedBox(height: 16),

              // Device list section
              BleDeviceListSection(
                devices: _devices,
                connectedDeviceId: _connection?.deviceInfo.id,
                onDeviceTap: _connection == null
                    ? (device) => _connectToDevice(device)
                    : null,
              ),
              if (_devices.isNotEmpty) const SizedBox(height: 16),

              // Connection section
              BleConnectionSection(
                connection: _connection,
                onDisconnect: _disconnect,
              ),
              if (_connection != null) const SizedBox(height: 16),

              // GATT section
              BleGattSection(
                gattInfo: _gattInfo,
                onCharacteristicSelected: _selectCharacteristic,
              ),
              if (_gattInfo != null) const SizedBox(height: 16),

              // JSON section
              BleJsonSection(
                selectedService: _selectedService,
                selectedCharacteristic: _selectedCharacteristic,
                jsonConnection: _jsonConnection,
                jsonController: _jsonController,
                onSend: _sendJson,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

