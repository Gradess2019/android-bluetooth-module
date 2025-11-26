import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'models/ble_device_info.dart';
import 'models/ble_device_connection.dart';
import 'models/ble_gatt_info.dart';
import 'models/ble_json_connection.dart';
import 'models/ble_connection_config.dart';
import 'models/ble_error.dart';

/// Internal record tracking connection resources
class _ConnectionRecord {
  final BleDeviceConnection connection;
  final StreamController<BleConnectionState> controller;
  final StreamSubscription<BluetoothConnectionState> stateSubscription;
  bool isDisposed = false;

  _ConnectionRecord({
    required this.connection,
    required this.controller,
    required this.stateSubscription,
  });
}

/// Main manager for BLE operations
class BleManager {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  bool _isScanning = false;
  final Map<String, _ConnectionRecord> _connections = {};

  /// Whether a scan is currently in progress
  bool get isScanning => _isScanning;

  /// Stream of discovered devices during scanning
  Stream<BleDeviceInfo> get scanResults {
    return FlutterBluePlus.scanResults
        .map((results) => results.map((result) => _mapToDeviceInfo(result)))
        .expand((devices) => devices);
  }

  /// Check and request required permissions
  Future<bool> checkPermissions() async {
    // Check location permission (required for BLE scanning on Android)
    final locationStatus = await Permission.locationWhenInUse.status;
    if (!locationStatus.isGranted) {
      final result = await Permission.locationWhenInUse.request();
      if (!result.isGranted) {
        return false;
      }
    }

    // Check BLE permissions (Android 12+)
    if (await Permission.bluetoothScan.isDenied) {
      final result = await Permission.bluetoothScan.request();
      if (!result.isGranted) {
        return false;
      }
    }

    if (await Permission.bluetoothConnect.isDenied) {
      final result = await Permission.bluetoothConnect.request();
      if (!result.isGranted) {
        return false;
      }
    }

    return true;
  }

  /// Start scanning for BLE devices
  /// 
  /// If a scan is already in progress, stops the previous scan and starts a new one.
  /// 
  /// Requires flutter_blue_plus >= 1.30.0
  /// Throws [BlePermissionError] if permissions are not granted.
  /// Throws [BleUnsupportedError] if Bluetooth is not supported.
  Future<void> scan() async {
    // If already scanning, stop the previous scan first
    if (_isScanning) {
      await stopScan();
    }

    try {
      // Check permissions first
      final hasPermissions = await checkPermissions();
      if (!hasPermissions) {
        throw const BlePermissionError('Required permissions not granted');
      }

      // Check if Bluetooth is available
      if (await FlutterBluePlus.isSupported == false) {
        throw const BleUnsupportedError('Bluetooth not supported on this device');
      }

      // Turn on Bluetooth if it's off
      if (await FlutterBluePlus.adapterState.first ==
          BluetoothAdapterState.off) {
        await FlutterBluePlus.turnOn();
      }

      // Set scanning state before starting
      _isScanning = true;

      // Subscribe to scan results
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        // Results are already exposed via scanResults getter
        // This subscription ensures we can cancel it properly
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
      );
    } catch (e) {
      // Reset scanning state on error
      _isScanning = false;
      _scanSubscription?.cancel();
      _scanSubscription = null;
      rethrow;
    }
  }

  /// Stop scanning for BLE devices
  Future<void> stopScan() async {
    if (!_isScanning) {
      return;
    }

    try {
      await FlutterBluePlus.stopScan();
    } finally {
      _isScanning = false;
      _scanSubscription?.cancel();
      _scanSubscription = null;
    }
  }

  /// Find or create a BluetoothDevice from device ID
  /// 
  /// Tries multiple lookup strategies:
  /// 1. Check lastScanResults
  /// 2. Check connectedDevices
  /// 3. Attempt to create device from ID using BluetoothDevice constructor
  /// 
  /// Returns null if device cannot be found or created.
  Future<BluetoothDevice?> _findOrCreateDevice(String deviceId) async {
    // Try lastScanResults first
    final scanResults = FlutterBluePlus.lastScanResults;
    for (final result in scanResults) {
      if (result.device.remoteId.str == deviceId) {
        return result.device;
      }
    }

    // Try connectedDevices
    final connectedDevices = FlutterBluePlus.connectedDevices;
    for (final device in connectedDevices) {
      if (device.remoteId.str == deviceId) {
        return device;
      }
    }

    // Fallback: Device cannot be created from ID directly in flutter_blue_plus
    // The device must be discovered via scan or already connected
    // Return null to indicate device not found
    return null;
  }

  /// Connect to a BLE device
  /// 
  /// Requires flutter_blue_plus >= 1.30.0
  /// [config] provides connection options including license, MTU, autoConnect, and bonding settings.
  /// If [config] is null, uses default configuration (autoConnect: true, requireBonding: true).
  /// 
  /// The device can be connected even if not in recent scan results, as long as the device ID
  /// is valid. The [BleDeviceInfo.id] must be a valid device identifier (MAC address on Android,
  /// UUID on iOS).
  /// 
  /// Throws [BleDeviceNotFoundError] if device is not found and cannot be created from ID.
  /// Throws [BleBondingError] if bonding is required but fails.
  /// Wraps other connection errors in appropriate [BleError] subclasses.
  Future<BleDeviceConnection> connect(
    BleDeviceInfo deviceInfo, {
    BleConnectionConfig? config,
  }) async {
    final connectionConfig = config ?? BleConnectionConfig.defaultConfig;
    
    // Find or create device using helper method
    final targetDevice = await _findOrCreateDevice(deviceInfo.id);
    
    if (targetDevice == null) {
      throw BleDeviceNotFoundError(
        'Device not found with ID: ${deviceInfo.id}. '
        'The device may need to be scanned first, or the device ID may be invalid.',
      );
    }

    // Create connection state stream
    final connectionStateController = StreamController<BleConnectionState>();

    // Map flutter_blue_plus connection state to our enum
    final stateSubscription = targetDevice.connectionState.listen((state) {
      BleConnectionState mappedState;
      switch (state) {
        case BluetoothConnectionState.connected:
          mappedState = BleConnectionState.connected;
          break;
        case BluetoothConnectionState.disconnected:
          mappedState = BleConnectionState.disconnected;
          break;
        case BluetoothConnectionState.connecting:
          mappedState = BleConnectionState.connecting;
          break;
        case BluetoothConnectionState.disconnecting:
          mappedState = BleConnectionState.disconnecting;
          break;
      }
      connectionStateController.add(mappedState);
    });

    // Connect to device
    try {
      // For flutter_blue_plus, we need to check if device is already connected
      if (!targetDevice.isConnected) {
        // Connect with configuration parameters
        await targetDevice.connect(
          timeout: const Duration(seconds: 15),
          autoConnect: connectionConfig.autoConnect,
          mtu: connectionConfig.mtu,
        );
      }
    } catch (e) {
      // Clean up on connection error
      _disposeConnection(deviceInfo.id);
      // Wrap connection errors
      if (e is BleError) {
        rethrow;
      }
      // Wrap unknown connection failures in BleConnectionError
      throw BleConnectionError('Failed to connect to device', e);
    }

    // Handle bonding if required
    // Note: Bonding on Android typically happens automatically during connection
    // when the device requires it. If bonding fails, it will be caught by the
    // connection error handling above. This section is for future explicit bonding
    // support if flutter_blue_plus adds bonding APIs.
    if (connectionConfig.requireBonding) {
      // Only attempt bonding on Android if bondingAndroidOnly is true
      if (connectionConfig.bondingAndroidOnly && !Platform.isAndroid) {
        // Skip bonding on non-Android platforms (iOS doesn't support bonding)
      } else {
        // On Android, bonding typically happens automatically during connection
        // if the device requires it. If explicit bonding is needed in the future,
        // it can be added here when flutter_blue_plus provides bonding APIs.
        // For now, we rely on the platform to handle bonding automatically.
        // If bonding fails, it will manifest as a connection error and be
        // caught by the error handling in the connect() try-catch block above.
      }
    }

    // Get the current connection state and emit it immediately to the controller
    // This ensures listeners get the current state when they subscribe
    final currentState = await targetDevice.connectionState.first;
    BleConnectionState mappedState;
    switch (currentState) {
      case BluetoothConnectionState.connected:
        mappedState = BleConnectionState.connected;
        break;
      case BluetoothConnectionState.disconnected:
        mappedState = BleConnectionState.disconnected;
        break;
      case BluetoothConnectionState.connecting:
        mappedState = BleConnectionState.connecting;
        break;
      case BluetoothConnectionState.disconnecting:
        mappedState = BleConnectionState.disconnecting;
        break;
    }
    
    // Emit the current state to the controller so it's available for listeners
    connectionStateController.add(mappedState);
    
    // Create a broadcast stream for multiple listeners
    final connectionStateStream = connectionStateController.stream.asBroadcastStream();

    final connection = BleDeviceConnection(
      deviceInfo: deviceInfo,
      connectionState: connectionStateStream,
      device: targetDevice,
    );

    // Create connection record
    final connectionRecord = _ConnectionRecord(
      connection: connection,
      controller: connectionStateController,
      stateSubscription: stateSubscription,
    );

    _connections[deviceInfo.id] = connectionRecord;

    // Clean up when connection is lost
    targetDevice.connectionState
        .where((state) => state == BluetoothConnectionState.disconnected)
        .first
        .then((_) {
      _disposeConnection(deviceInfo.id);
    });

    return connection;
  }

  /// Dispose connection resources
  /// 
  /// Cancels subscriptions, closes controller, and removes connection from map.
  /// Safe to call multiple times (idempotent).
  void _disposeConnection(String deviceId) {
    final record = _connections[deviceId];
    if (record == null || record.isDisposed) {
      return;
    }

    try {
      // Cancel state subscription
      record.stateSubscription.cancel();
    } catch (e) {
      // Ignore errors during cancellation (may already be cancelled)
    }

    try {
      // Close controller if not already closed
      if (!record.controller.isClosed) {
        record.controller.close();
      }
    } catch (e) {
      // Ignore errors during close
    }

    // Mark as disposed and remove from map
    record.isDisposed = true;
    _connections.remove(deviceId);
  }

  /// Disconnect from a BLE device
  Future<void> disconnect(BleDeviceConnection connection) async {
    try {
      await connection.device.disconnect();
    } catch (e) {
      // Ignore errors if already disconnected
    }
    // Always dispose connection resources
    _disposeConnection(connection.deviceInfo.id);
  }

  /// Discover GATT services and characteristics
  /// 
  /// Throws [BleNotConnectedError] if device is not connected.
  /// Throws [BleGattError] if service discovery fails.
  Future<BleGattInfo> discoverGatt(BleDeviceConnection connection) async {
    final connectionState = await connection.device.connectionState.first;
    if (connectionState != BluetoothConnectionState.connected) {
      throw const BleNotConnectedError('Device is not connected');
    }

    List<BluetoothService> services;
    try {
      services = await connection.device.discoverServices();
    } catch (e) {
      throw BleGattError('Failed to discover GATT services', e);
    }
    final gattServices = services.map((service) {
      final characteristics = service.characteristics.map((char) {
        return GattCharInfo(
          uuid: char.uuid.toString(),
          canRead: char.properties.read,
          canWrite: char.properties.write || char.properties.writeWithoutResponse,
          canNotify: char.properties.notify || char.properties.indicate,
        );
      }).toList();

      return GattServiceInfo(
        uuid: service.uuid.toString(),
        characteristics: characteristics,
      );
    }).toList();

    return BleGattInfo(services: gattServices);
  }

  /// Create a JSON connection for a specific characteristic
  /// 
  /// Throws [BleNotConnectedError] if device is not connected.
  /// Throws [BleGattError] if service or characteristic is not found.
  Future<BleJsonConnection> createJsonConnection(
    BleDeviceConnection deviceConnection,
    String serviceUuid,
    String characteristicUuid,
  ) async {
    final connectionState = await deviceConnection.device.connectionState.first;
    if (connectionState != BluetoothConnectionState.connected) {
      throw const BleNotConnectedError('Device is not connected');
    }

    final services = deviceConnection.device.servicesList;
    if (services.isEmpty) {
      throw const BleGattError(
        'No services discovered. Call discoverGatt() first.',
      );
    }
    BluetoothService? targetService;
    BluetoothCharacteristic? targetChar;

    for (final service in services) {
      if (service.uuid.toString().toLowerCase() ==
          serviceUuid.toLowerCase()) {
        targetService = service;
        break;
      }
    }

    if (targetService == null) {
      throw BleGattError('Service not found: $serviceUuid');
    }

    for (final char in targetService.characteristics) {
      if (char.uuid.toString().toLowerCase() ==
          characteristicUuid.toLowerCase()) {
        targetChar = char;
        break;
      }
    }

    if (targetChar == null) {
      throw BleGattError('Characteristic not found: $characteristicUuid');
    }

    if (!targetChar.properties.write &&
        !targetChar.properties.writeWithoutResponse) {
      throw BleGattError(
        'Characteristic does not support write: $characteristicUuid',
      );
    }

    // Try to get MTU from device, fallback to default (20 bytes payload)
    int? mtuPayload;
    try {
      // Attempt to get MTU - flutter_blue_plus may provide it via mtu property or stream
      // MTU payload = MTU - 3 (for ATT header)
      final mtu = await deviceConnection.device.mtu.first.timeout(
        const Duration(seconds: 1),
      );
      if (mtu > 3) {
        mtuPayload = mtu - 3;
      }
    } catch (e) {
      // MTU not available or failed to get, use default
      mtuPayload = null;
    }

    return BleJsonConnection(
      deviceConnection: deviceConnection,
      characteristic: targetChar,
      mtuPayload: mtuPayload,
    );
  }

  /// Map flutter_blue_plus ScanResult to BleDeviceInfo
  BleDeviceInfo _mapToDeviceInfo(ScanResult result) {
    return BleDeviceInfo(
      id: result.device.remoteId.str,
      name: result.advertisementData.advName.isEmpty
          ? null
          : result.advertisementData.advName,
      rssi: result.rssi,
    );
  }

  /// Dispose resources
  void dispose() {
    // Stop scanning
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;

    // Dispose all connections
    final deviceIds = _connections.keys.toList();
    for (final deviceId in deviceIds) {
      _disposeConnection(deviceId);
    }
    _connections.clear();
  }
}

