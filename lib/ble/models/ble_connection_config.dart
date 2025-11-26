/// Configuration for BLE device connection
class BleConnectionConfig {
  /// License key for flutter_blue_plus (optional, for commercial use)
  final String? license;

  /// MTU (Maximum Transmission Unit) to negotiate during connection
  /// If null, uses default MTU. Payload size will be MTU - 3 bytes.
  final int? mtu;

  /// Whether to automatically reconnect if connection is lost
  /// Default: true
  final bool autoConnect;

  /// Whether bonding/pairing is required for the connection
  /// Default: true (opt-out behavior)
  final bool requireBonding;

  /// Whether bonding should only be attempted on Android
  /// Default: true (iOS doesn't support bonding)
  final bool bondingAndroidOnly;

  const BleConnectionConfig({
    this.license,
    this.mtu,
    this.autoConnect = true,
    this.requireBonding = true,
    this.bondingAndroidOnly = true,
  });

  /// Default configuration with sensible defaults
  static const BleConnectionConfig defaultConfig = BleConnectionConfig();
}

