import 'package:flutter_test/flutter_test.dart';
import 'package:neo_bluetooth_module/ble/models/ble_error.dart';

void main() {
  group('BleError hierarchy tests', () {
    test('BlePermissionError can be instantiated', () {
      const error = BlePermissionError('Permission denied');
      expect(error.message, equals('Permission denied'));
      expect(error.originalError, isNull);
      expect(error.toString(), contains('BlePermissionError'));
    });

    test('BleUnsupportedError can be instantiated', () {
      const error = BleUnsupportedError('Bluetooth not supported');
      expect(error.message, equals('Bluetooth not supported'));
      expect(error.toString(), contains('BleUnsupportedError'));
    });

    test('BleDeviceNotFoundError can be instantiated', () {
      const error = BleDeviceNotFoundError('Device not found');
      expect(error.message, equals('Device not found'));
      expect(error.toString(), contains('BleDeviceNotFoundError'));
    });

    test('BleNotConnectedError can be instantiated', () {
      const error = BleNotConnectedError('Device not connected');
      expect(error.message, equals('Device not connected'));
      expect(error.toString(), contains('BleNotConnectedError'));
    });

    test('BleGattError can be instantiated', () {
      const error = BleGattError('GATT service not found');
      expect(error.message, equals('GATT service not found'));
      expect(error.toString(), contains('BleGattError'));
    });

    test('BleBondingError can be instantiated', () {
      const error = BleBondingError('Bonding failed');
      expect(error.message, equals('Bonding failed'));
      expect(error.toString(), contains('BleBondingError'));
    });

    test('BleConnectionError can be instantiated', () {
      const error = BleConnectionError('Connection failed');
      expect(error.message, equals('Connection failed'));
      expect(error.toString(), contains('BleConnectionError'));
    });

    test('errors preserve original error', () {
      final originalError = Exception('Original error');
      final error = BlePermissionError('Permission denied', originalError);
      
      expect(error.originalError, equals(originalError));
      expect(error.toString(), contains('original error'));
    });

    test('all error types extend BleError', () {
      expect(const BlePermissionError('test'), isA<BleError>());
      expect(const BleUnsupportedError('test'), isA<BleError>());
      expect(const BleDeviceNotFoundError('test'), isA<BleError>());
      expect(const BleNotConnectedError('test'), isA<BleError>());
      expect(const BleGattError('test'), isA<BleError>());
      expect(const BleBondingError('test'), isA<BleError>());
      expect(const BleConnectionError('test'), isA<BleError>());
    });

    test('all error types implement Exception', () {
      expect(const BlePermissionError('test'), isA<Exception>());
      expect(const BleUnsupportedError('test'), isA<Exception>());
      expect(const BleDeviceNotFoundError('test'), isA<Exception>());
      expect(const BleNotConnectedError('test'), isA<Exception>());
      expect(const BleGattError('test'), isA<Exception>());
      expect(const BleBondingError('test'), isA<Exception>());
      expect(const BleConnectionError('test'), isA<Exception>());
    });
  });
}

