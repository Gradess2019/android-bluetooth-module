import 'ble_error.dart';

/// Error thrown when a BLE write operation fails
class BleWriteError extends BleError {
  const BleWriteError(super.message, [super.originalError]);
}

