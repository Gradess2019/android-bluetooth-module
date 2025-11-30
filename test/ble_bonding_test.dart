import 'package:flutter_test/flutter_test.dart';
import 'package:neo_bluetooth_module/ble/models/ble_connection_config.dart';
import 'package:neo_bluetooth_module/ble/models/ble_error.dart';

void main() {
  group('Bonding configuration tests', () {
    test('default config requires bonding', () {
      const config = BleConnectionConfig.defaultConfig;
      expect(config.requireBonding, isTrue);
      expect(config.bondingAndroidOnly, isTrue);
    });

    test('can disable bonding', () {
      const config = BleConnectionConfig(
        requireBonding: false,
      );
      expect(config.requireBonding, isFalse);
    });

    test('can enable bonding for all platforms', () {
      const config = BleConnectionConfig(
        requireBonding: true,
        bondingAndroidOnly: false,
      );
      expect(config.requireBonding, isTrue);
      expect(config.bondingAndroidOnly, isFalse);
    });

    test('BleBondingError can be thrown for bonding failures', () {
      const error = BleBondingError('Bonding failed');
      expect(error, isA<BleError>());
      expect(error, isA<Exception>());
      expect(error.message, equals('Bonding failed'));
    });

    // Note: Full bonding flow tests would require:
    // 1. Mocking BluetoothDevice and flutter_blue_plus
    // 2. Simulating bonding success/failure scenarios
    // 3. Testing platform-specific behavior (Android vs iOS)
    // These tests verify the configuration and error types are correct.
    // Integration tests with actual hardware would be needed for full coverage.
  });
}

