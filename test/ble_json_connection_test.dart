import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:neo_bluetooth_module/ble/models/ble_json_connection.dart';
import 'package:neo_bluetooth_module/ble/models/ble_device_connection.dart';
import 'package:neo_bluetooth_module/ble/models/ble_device_info.dart';
import 'package:neo_bluetooth_module/ble/models/ble_write_error.dart';

// Mock classes for testing
class MockBluetoothCharacteristic extends Fake implements BluetoothCharacteristic {
  final List<List<int>> writtenData = [];
  bool shouldThrowError = false;
  String? errorMessage;

  @override
  Future<void> write(
    List<int> value, {
    bool withoutResponse = false,
    bool allowLongWrite = true,
    int timeout = 35,
  }) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Write failed');
    }
    writtenData.add(List<int>.from(value));
  }
}

class MockBluetoothDevice extends Fake implements BluetoothDevice {}

void main() {
  group('BleJsonConnection chunking tests', () {
    late MockBluetoothCharacteristic mockCharacteristic;
    late BleDeviceConnection mockDeviceConnection;
    late BleJsonConnection jsonConnection;

    setUp(() {
      mockCharacteristic = MockBluetoothCharacteristic();
      final mockDevice = MockBluetoothDevice();
      mockDeviceConnection = BleDeviceConnection(
        deviceInfo: BleDeviceInfo(id: 'test-id', name: 'Test Device', rssi: -50),
        connectionState: const Stream.empty(),
        device: mockDevice,
      );
    });

    test('short JSON (≤ mtuPayload) sends exactly one chunk', () async {
      // Use small mtuPayload for testing
      jsonConnection = BleJsonConnection(
        deviceConnection: mockDeviceConnection,
        characteristic: mockCharacteristic,
        mtuPayload: 20,
      );

      // Create JSON that fits in one chunk (including newline)
      const shortJson = '{"key":"value"}'; // 15 bytes + 1 newline = 16 bytes
      await jsonConnection.sendJsonString(shortJson);

      expect(mockCharacteristic.writtenData.length, 1);
      final writtenBytes = mockCharacteristic.writtenData[0];
      expect(writtenBytes.last, 10); // newline byte
      expect(utf8.decode(writtenBytes), equals(shortJson + '\n'));
    });

    test('long JSON (> mtuPayload) sends multiple chunks', () async {
      jsonConnection = BleJsonConnection(
        deviceConnection: mockDeviceConnection,
        characteristic: mockCharacteristic,
        mtuPayload: 20,
      );

      // Create JSON that exceeds mtuPayload
      final longJson = '{"data":"${'x' * 100}"}'; // > 100 bytes
      await jsonConnection.sendJsonString(longJson);

      expect(mockCharacteristic.writtenData.length, greaterThan(1));
      
      // Verify each chunk is ≤ mtuPayload
      for (final chunk in mockCharacteristic.writtenData) {
        expect(chunk.length, lessThanOrEqualTo(20));
      }

      // Verify final chunk ends with newline
      final finalChunk = mockCharacteristic.writtenData.last;
      expect(finalChunk.last, 10); // newline byte

      // Verify all chunks together reconstruct the original message
      final reconstructed = mockCharacteristic.writtenData
          .expand((chunk) => chunk)
          .toList();
      expect(utf8.decode(reconstructed), equals(longJson + '\n'));
    });

    test('final chunk ends with newline, earlier chunks do not', () async {
      jsonConnection = BleJsonConnection(
        deviceConnection: mockDeviceConnection,
        characteristic: mockCharacteristic,
        mtuPayload: 20,
      );

      final longJson = '{"data":"${'x' * 50}"}';
      await jsonConnection.sendJsonString(longJson);

      expect(mockCharacteristic.writtenData.length, greaterThan(1));

      // All chunks except the last should not end with newline
      for (int i = 0; i < mockCharacteristic.writtenData.length - 1; i++) {
        final chunk = mockCharacteristic.writtenData[i];
        expect(chunk.last, isNot(10)); // not newline
      }

      // Final chunk must end with newline
      final finalChunk = mockCharacteristic.writtenData.last;
      expect(finalChunk.last, 10); // newline byte
    });

    test('edge case: JSON length exactly mtuPayload - 1', () async {
      jsonConnection = BleJsonConnection(
        deviceConnection: mockDeviceConnection,
        characteristic: mockCharacteristic,
        mtuPayload: 20,
      );

      // Create JSON that is exactly 19 bytes (20 - 1 for newline)
      final edgeJson = 'x' * 19;
      await jsonConnection.sendJsonString(edgeJson);

      // Should send in one chunk (19 bytes + 1 newline = 20 bytes)
      expect(mockCharacteristic.writtenData.length, 1);
      expect(mockCharacteristic.writtenData[0].length, 20);
      expect(mockCharacteristic.writtenData[0].last, 10); // newline
    });

    test('edge case: JSON length exactly mtuPayload', () async {
      jsonConnection = BleJsonConnection(
        deviceConnection: mockDeviceConnection,
        characteristic: mockCharacteristic,
        mtuPayload: 20,
      );

      // Create JSON that is exactly 20 bytes (will be 21 with newline)
      final edgeJson = 'x' * 20;
      await jsonConnection.sendJsonString(edgeJson);

      // Should send in two chunks: first 20 bytes, second 1 byte (newline)
      expect(mockCharacteristic.writtenData.length, 2);
      expect(mockCharacteristic.writtenData[0].length, 20);
      expect(mockCharacteristic.writtenData[1].length, 1);
      expect(mockCharacteristic.writtenData[1].last, 10); // newline
    });

    test('wraps write errors in BleWriteError', () async {
      jsonConnection = BleJsonConnection(
        deviceConnection: mockDeviceConnection,
        characteristic: mockCharacteristic,
        mtuPayload: 20,
      );

      mockCharacteristic.shouldThrowError = true;
      mockCharacteristic.errorMessage = 'BLE write failed';

      expect(
        () => jsonConnection.sendJsonString('{"test":"data"}'),
        throwsA(isA<BleWriteError>()),
      );
    });

    test('sendJson calls sendJsonString correctly', () async {
      jsonConnection = BleJsonConnection(
        deviceConnection: mockDeviceConnection,
        characteristic: mockCharacteristic,
        mtuPayload: 100, // Use larger payload to ensure single chunk
      );

      final jsonData = {'key': 'value', 'number': 42};
      await jsonConnection.sendJson(jsonData);

      // Verify all chunks together form valid JSON
      final allBytes = mockCharacteristic.writtenData
          .expand((chunk) => chunk)
          .toList();
      final decoded = utf8.decode(allBytes);
      expect(decoded, endsWith('\n'));
      
      // Verify it's valid JSON
      final jsonStr = decoded.trim();
      final parsed = jsonDecode(jsonStr);
      expect(parsed, equals(jsonData));
    });
  });
}

