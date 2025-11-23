import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_device_connection.dart';

/// Connection for sending JSON data over BLE
class BleJsonConnection {
  final BleDeviceConnection deviceConnection;
  final BluetoothCharacteristic characteristic;

  BleJsonConnection({
    required this.deviceConnection,
    required this.characteristic,
  });

  /// Send a JSON object as UTF-8 encoded bytes
  Future<void> sendJson(Map<String, dynamic> json) async {
    final jsonString = jsonEncode(json);
    await sendJsonString(jsonString);
  }

  /// Send a JSON string as UTF-8 encoded bytes
  Future<void> sendJsonString(String jsonString) async {
    final bytes = utf8.encode(jsonString + '\n');
    await characteristic.write(bytes, withoutResponse: false);
  }
}

