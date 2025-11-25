/// Exception thrown when a BLE write operation fails
class BleWriteError implements Exception {
  final String message;
  final Object? originalError;

  BleWriteError(this.message, [this.originalError]);

  @override
  String toString() {
    if (originalError != null) {
      return 'BleWriteError: $message (original error: $originalError)';
    }
    return 'BleWriteError: $message';
  }
}

