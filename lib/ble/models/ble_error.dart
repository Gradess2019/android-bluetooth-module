/// Base class for all BLE-related errors
abstract class BleError implements Exception {
  /// Human-readable error message
  final String message;

  /// Original error that caused this BLE error (if any)
  final Object? originalError;

  const BleError(this.message, [this.originalError]);

  @override
  String toString() {
    if (originalError != null) {
      return '$runtimeType: $message (original error: $originalError)';
    }
    return '$runtimeType: $message';
  }
}

/// Error thrown when BLE permissions are not granted
class BlePermissionError extends BleError {
  const BlePermissionError(super.message, [super.originalError]);
}

/// Error thrown when Bluetooth is not supported on the device
class BleUnsupportedError extends BleError {
  const BleUnsupportedError(super.message, [super.originalError]);
}

/// Error thrown when a requested BLE device is not found
class BleDeviceNotFoundError extends BleError {
  const BleDeviceNotFoundError(super.message, [super.originalError]);
}

/// Error thrown when an operation requires a connected device but device is not connected
class BleNotConnectedError extends BleError {
  const BleNotConnectedError(super.message, [super.originalError]);
}

/// Error thrown when GATT service or characteristic discovery fails
class BleGattError extends BleError {
  const BleGattError(super.message, [super.originalError]);
}

/// Error thrown when bonding/pairing fails
class BleBondingError extends BleError {
  const BleBondingError(super.message, [super.originalError]);
}

/// Error thrown when a connection operation fails for unknown reasons
class BleConnectionError extends BleError {
  const BleConnectionError(super.message, [super.originalError]);
}

