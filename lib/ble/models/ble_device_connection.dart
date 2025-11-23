import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_device_info.dart';

/// Connection state of a BLE device
enum BleConnectionState {
  connecting,
  connected,
  disconnected,
  error,
}

/// Represents a connection to a BLE device
class BleDeviceConnection {
  final BleDeviceInfo deviceInfo;
  final Stream<BleConnectionState> connectionState;
  final BluetoothDevice _device;

  BleDeviceConnection({
    required this.deviceInfo,
    required this.connectionState,
    required BluetoothDevice device,
  }) : _device = device;

  /// Internal access to the underlying BluetoothDevice
  BluetoothDevice get device => _device;

  @override
  String toString() => 'BleDeviceConnection(device: $deviceInfo)';
}

