import 'package:flutter_test/flutter_test.dart';
import 'package:neo_bluetooth_module/ble/models/ble_connection_config.dart';

void main() {
  group('BleConnectionConfig tests', () {
    test('default config has correct default values', () {
      const config = BleConnectionConfig.defaultConfig;
      
      expect(config.license, isNull);
      expect(config.mtu, isNull);
      expect(config.autoConnect, isTrue);
      expect(config.requireBonding, isTrue);
      expect(config.bondingAndroidOnly, isTrue);
    });

    test('can create config with custom values', () {
      const config = BleConnectionConfig(
        license: 'test-license',
        mtu: 512,
        autoConnect: false,
        requireBonding: false,
        bondingAndroidOnly: false,
      );
      
      expect(config.license, equals('test-license'));
      expect(config.mtu, equals(512));
      expect(config.autoConnect, isFalse);
      expect(config.requireBonding, isFalse);
      expect(config.bondingAndroidOnly, isFalse);
    });

    test('can create config with partial values', () {
      const config = BleConnectionConfig(
        mtu: 256,
        autoConnect: false,
      );
      
      expect(config.license, isNull);
      expect(config.mtu, equals(256));
      expect(config.autoConnect, isFalse);
      expect(config.requireBonding, isTrue); // default
      expect(config.bondingAndroidOnly, isTrue); // default
    });
  });
}

