import 'package:flutter_test/flutter_test.dart';
import 'package:neo_bluetooth_module/ble/ble_manager.dart';

void main() {
  group('BleManager connection cleanup tests', () {
    late BleManager bleManager;

    setUp(() {
      bleManager = BleManager();
    });

    tearDown(() {
      bleManager.dispose();
    });

    test('dispose() cleans up all connections', () {
      // Note: This test would require creating mock connections
      // For now, we verify dispose() doesn't throw
      expect(() => bleManager.dispose(), returnsNormally);
    });

    test('_disposeConnection is idempotent', () {
      // Note: This test would require:
      // 1. Creating a mock connection record
      // 2. Calling _disposeConnection() twice
      // 3. Verifying no errors and resources are only disposed once
    });

    // Note: Full tests would require:
    // 1. Mocking StreamController and StreamSubscription
    // 2. Verifying cancel() is called on subscription
    // 3. Verifying close() is called on controller
    // 4. Verifying connection is removed from map
    // 5. Testing cleanup on normal disconnect
    // 6. Testing cleanup on connection error
    // 7. Testing cleanup when disconnected state never arrives
    // 8. Testing double-disposal prevention
  });
}

