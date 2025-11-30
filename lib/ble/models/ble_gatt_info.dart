/// Information about a GATT characteristic
class GattCharInfo {
  /// Characteristic UUID
  final String uuid;

  /// Whether this characteristic can be read
  final bool canRead;

  /// Whether this characteristic can be written to
  final bool canWrite;

  /// Whether this characteristic supports notifications
  final bool canNotify;

  GattCharInfo({
    required this.uuid,
    required this.canRead,
    required this.canWrite,
    required this.canNotify,
  });

  @override
  String toString() =>
      'GattCharInfo(uuid: $uuid, read: $canRead, write: $canWrite, notify: $canNotify)';
}

/// Information about a GATT service
class GattServiceInfo {
  /// Service UUID
  final String uuid;

  /// List of characteristics in this service
  final List<GattCharInfo> characteristics;

  GattServiceInfo({
    required this.uuid,
    required this.characteristics,
  });

  @override
  String toString() =>
      'GattServiceInfo(uuid: $uuid, characteristics: ${characteristics.length})';
}

/// Complete GATT information for a device
class BleGattInfo {
  /// List of all services discovered on the device
  final List<GattServiceInfo> services;

  BleGattInfo({required this.services});

  @override
  String toString() => 'BleGattInfo(services: ${services.length})';
}

