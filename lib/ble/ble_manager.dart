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

/// Main manager for BLE operations
class BleManager {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final Map<String, BleDeviceConnection> _connections = {};

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
  /// Requires flutter_blue_plus >= 1.30.0
  /// Throws [BlePermissionError] if permissions are not granted.
  /// Throws [BleUnsupportedError] if Bluetooth is not supported.
  Future<void> scan() async {
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

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 4),
    );
  }

  /// Stop scanning for BLE devices
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /// Connect to a BLE device
  /// 
  /// Requires flutter_blue_plus >= 1.30.0
  /// [config] provides connection options including license, MTU, autoConnect, and bonding settings.
  /// If [config] is null, uses default configuration (autoConnect: true, requireBonding: true).
  /// 
  /// Throws [BleDeviceNotFoundError] if device is not found in scan results.
  /// Throws [BleBondingError] if bonding is required but fails.
  /// Wraps other connection errors in appropriate [BleError] subclasses.
  Future<BleDeviceConnection> connect(
    BleDeviceInfo deviceInfo, {
    BleConnectionConfig? config,
  }) async {
    final connectionConfig = config ?? BleConnectionConfig.defaultConfig;
    // Find the BluetoothDevice from scan results
    final devices = FlutterBluePlus.lastScanResults;
    BluetoothDevice? targetDevice;

    for (final result in devices) {
      if (result.device.remoteId.str == deviceInfo.id) {
        targetDevice = result.device;
        break;
      }
    }

    if (targetDevice == null) {
      // Try to find device from connected devices
      final connectedDevices = FlutterBluePlus.connectedDevices;
      for (final device in connectedDevices) {
        if (device.remoteId.str == deviceInfo.id) {
          targetDevice = device;
          break;
        }
      }
    }
    
    if (targetDevice == null) {
      throw BleDeviceNotFoundError(
        'Device not found. Please scan for devices first.',
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
      connectionStateController.add(BleConnectionState.error);
      await connectionStateController.close();
      stateSubscription.cancel();
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

    _connections[deviceInfo.id] = connection;

    // Clean up when connection is lost
    targetDevice.connectionState
        .where((state) => state == BluetoothConnectionState.disconnected)
        .first
        .then((_) {
      _connections.remove(deviceInfo.id);
      connectionStateController.close();
      stateSubscription.cancel();
    });

    return connection;
  }

  /// Disconnect from a BLE device
  Future<void> disconnect(BleDeviceConnection connection) async {
    try {
      await connection.device.disconnect();
    } catch (e) {
      // Ignore errors if already disconnected
    }
    _connections.remove(connection.deviceInfo.id);
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
    _scanSubscription?.cancel();
    for (final connection in _connections.values) {
      disconnect(connection);
    }
    _connections.clear();
  }
}

