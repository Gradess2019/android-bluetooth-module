import 'package:neo_bluetooth_module/ble/ble.dart';

/// Result of the BLE JSON connection flow
class BleJsonConnectionResult {
  /// The established JSON connection (null if cancelled or failed)
  final BleJsonConnection? jsonConnection;

  /// The device connection (null if cancelled or failed)
  final BleDeviceConnection? deviceConnection;

  /// The selected service (null if cancelled or failed)
  final GattServiceInfo? selectedService;

  /// The selected characteristic (null if cancelled or failed)
  final GattCharInfo? selectedCharacteristic;

  /// Whether the user cancelled the flow
  final bool cancelled;

  /// Error message if the flow failed
  final String? error;

  BleJsonConnectionResult({
    this.jsonConnection,
    this.deviceConnection,
    this.selectedService,
    this.selectedCharacteristic,
    this.cancelled = false,
    this.error,
  });

  /// Create a cancelled result
  factory BleJsonConnectionResult.cancelled() {
    return BleJsonConnectionResult(cancelled: true);
  }

  /// Create a success result
  factory BleJsonConnectionResult.success({
    required BleJsonConnection jsonConnection,
    required BleDeviceConnection deviceConnection,
    required GattServiceInfo selectedService,
    required GattCharInfo selectedCharacteristic,
  }) {
    return BleJsonConnectionResult(
      jsonConnection: jsonConnection,
      deviceConnection: deviceConnection,
      selectedService: selectedService,
      selectedCharacteristic: selectedCharacteristic,
      cancelled: false,
    );
  }

  /// Create an error result
  factory BleJsonConnectionResult.error(String error) {
    return BleJsonConnectionResult(
      cancelled: false,
      error: error,
    );
  }

  /// Whether the flow was successful
  bool get isSuccess => !cancelled && error == null && jsonConnection != null;
}

