/// Information about a discovered BLE device
class BleDeviceInfo {
  /// Device identifier (MAC address on Android, UUID on iOS)
  final String id;

  /// Device name (may be null if not advertised)
  final String? name;

  /// Signal strength in dBm
  final int rssi;

  BleDeviceInfo({
    required this.id,
    this.name,
    required this.rssi,
  });

  @override
  String toString() => 'BleDeviceInfo(id: $id, name: $name, rssi: $rssi)';
}

