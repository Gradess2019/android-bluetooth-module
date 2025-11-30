import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_device_connection.dart';
import 'ble_write_error.dart';

/// Connection for sending JSON data over BLE
class BleJsonConnection {
  final BleDeviceConnection deviceConnection;
  final BluetoothCharacteristic characteristic;
  final int _mtuPayload;

  /// Creates a BLE JSON connection
  /// 
  /// [mtuPayload] is the maximum payload size per BLE write operation.
  /// Default is 20 bytes (safe for default MTU of 23 bytes, leaving 3 bytes for ATT header).
  BleJsonConnection({
    required this.deviceConnection,
    required this.characteristic,
    int? mtuPayload,
  }) : _mtuPayload = mtuPayload ?? 20;

  /// Send a JSON object as UTF-8 encoded bytes
  Future<void> sendJson(Map<String, dynamic> json) async {
    final jsonString = jsonEncode(json);
    await sendJsonString(jsonString);
  }

  /// Send a JSON string as UTF-8 encoded bytes
  /// 
  /// The message will be chunked if it exceeds the MTU payload size.
  /// Messages are terminated with a newline character.
  Future<void> sendJsonString(String jsonString) async {
    await _sendJsonInternal(jsonString);
  }

  /// Internal method to send JSON with MTU-aware chunking
  /// 
  /// Builds the message with newline termination, encodes to UTF-8,
  /// and splits into chunks if necessary. The final chunk will contain
  /// the terminating newline.
  Future<void> _sendJsonInternal(String jsonString) async {
    // Build message with newline termination
    final msg = '$jsonString\n';
    
    // Encode once to UTF-8 bytes
    final bytes = utf8.encode(msg);
    
    // If message fits in one chunk, send directly
    if (bytes.length <= _mtuPayload) {
      try {
        await characteristic.write(bytes, withoutResponse: false);
      } catch (e) {
        throw BleWriteError('Failed to write JSON data', e);
      }
      return;
    }
    
    // Split into chunks and send sequentially
    for (int i = 0; i < bytes.length; i += _mtuPayload) {
      final end = (i + _mtuPayload < bytes.length) ? i + _mtuPayload : bytes.length;
      final chunk = bytes.sublist(i, end);
      
      try {
        await characteristic.write(chunk, withoutResponse: false);
      } catch (e) {
        throw BleWriteError('Failed to write JSON chunk at offset $i', e);
      }
    }
  }
}

