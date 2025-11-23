import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'models/ble_device_info.dart';
import 'models/ble_device_connection.dart';
import 'models/ble_gatt_info.dart';
import 'models/ble_json_connection.dart';

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
  Future<void> scan() async {
    // Check permissions first
    final hasPermissions = await checkPermissions();
    if (!hasPermissions) {
      throw Exception('Required permissions not granted');
    }

    // Check if Bluetooth is available
    if (await FlutterBluePlus.isSupported == false) {
      throw Exception('Bluetooth not supported on this device');
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
  Future<BleDeviceConnection> connect(BleDeviceInfo deviceInfo) async {
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
      throw Exception('Device not found. Please scan for devices first.');
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
        default:
          mappedState = BleConnectionState.error;
      }
      connectionStateController.add(mappedState);
    });

    // Connect to device
    try {
      // For flutter_blue_plus, we need to check if device is already connected
      if (!targetDevice.isConnected) {
        // Try connecting without explicit parameters first
        // If license is required, this will fail and we'll need to handle it
        await targetDevice.connect(
          timeout: const Duration(seconds: 15),
        );
      }
    } catch (e) {
      connectionStateController.add(BleConnectionState.error);
      await connectionStateController.close();
      stateSubscription.cancel();
      rethrow;
    }

    final connection = BleDeviceConnection(
      deviceInfo: deviceInfo,
      connectionState: connectionStateController.stream,
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
  Future<BleGattInfo> discoverGatt(BleDeviceConnection connection) async {
    final connectionState = await connection.device.connectionState.first;
    if (connectionState != BluetoothConnectionState.connected) {
      throw Exception('Device is not connected');
    }

    final services = await connection.device.discoverServices();
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
  Future<BleJsonConnection> createJsonConnection(
    BleDeviceConnection deviceConnection,
    String serviceUuid,
    String characteristicUuid,
  ) async {
    final connectionState = await deviceConnection.device.connectionState.first;
    if (connectionState != BluetoothConnectionState.connected) {
      throw Exception('Device is not connected');
    }

    final services = deviceConnection.device.servicesList;
    if (services.isEmpty) {
      throw Exception('No services discovered. Call discoverGatt() first.');
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
      throw Exception('Service not found: $serviceUuid');
    }

    for (final char in targetService.characteristics) {
      if (char.uuid.toString().toLowerCase() ==
          characteristicUuid.toLowerCase()) {
        targetChar = char;
        break;
      }
    }

    if (targetChar == null) {
      throw Exception('Characteristic not found: $characteristicUuid');
    }

    if (!targetChar.properties.write &&
        !targetChar.properties.writeWithoutResponse) {
      throw Exception(
          'Characteristic does not support write: $characteristicUuid');
    }

    return BleJsonConnection(
      deviceConnection: deviceConnection,
      characteristic: targetChar,
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

