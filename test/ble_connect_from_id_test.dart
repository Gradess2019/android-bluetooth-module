import 'package:flutter_test/flutter_test.dart';
import 'package:neo_bluetooth_module/ble/ble_manager.dart';
import 'package:neo_bluetooth_module/ble/models/ble_device_info.dart';
import 'package:neo_bluetooth_module/ble/models/ble_error.dart';

void main() {
  group('BleManager connect from device ID tests', () {
    late BleManager bleManager;

    setUp(() {
      bleManager = BleManager();
    });

    tearDown(() {
      bleManager.dispose();
    });

    test('connect with non-existent device throws BleDeviceNotFoundError', () {
      final deviceInfo = BleDeviceInfo(
        id: 'non-existent-device-id',
        name: 'Non-existent Device',
        rssi: -50,
      );

      expect(
        () => bleManager.connect(deviceInfo),
        throwsA(isA<BleDeviceNotFoundError>()),
      );
    });

    test('BleDeviceNotFoundError includes device ID in message', () {
      final deviceInfo = BleDeviceInfo(
        id: 'test-device-id-123',
        name: 'Test Device',
        rssi: -50,
      );

      expect(
        () => bleManager.connect(deviceInfo),
        throwsA(
          predicate<BleDeviceNotFoundError>(
            (e) => e.message.contains('test-device-id-123'),
          ),
        ),
      );
    });

    // Note: Full tests would require:
    // 1. Mocking FlutterBluePlus.lastScanResults
    // 2. Mocking FlutterBluePlus.connectedDevices
    // 3. Testing successful connection from scan results
    // 4. Testing successful connection from connected devices
    // 5. Verifying _findOrCreateDevice() is called with correct ID
  });
}

