<!-- 27abb8d2-3032-4aba-9604-aa4cb583ce4e dca5d574-a5b8-42e6-8671-a00288fd7252 -->
# Flutter BLE JSON Module Implementation

## Overview

Implement a Flutter/Dart library that wraps `flutter_blue_plus` to provide a high-level JSON API for BLE operations. The library will support device scanning, connection, GATT discovery, and JSON data transmission without hard-coded UUIDs.

## Implementation Steps

### 1. Add Dependencies

- Add `flutter_blue_plus: ^2.0.2` to `pubspec.yaml`
- Add `dart:convert` import (for JSON encoding)

### 2. Configure Android Permissions

- Update `android/app/src/main/AndroidManifest.xml` to add:
- `BLUETOOTH` permission
- `BLUETOOTH_ADMIN` permission
- `BLUETOOTH_SCAN` permission (Android 12+)
- `BLUETOOTH_CONNECT` permission (Android 12+)
- `ACCESS_FINE_LOCATION` permission (required for BLE scanning)
- `ACCESS_COARSE_LOCATION` permission (fallback)

### 3. Create Library Structure

Create the following files in `lib/`:

#### `lib/ble/ble_manager.dart`

- Implement `BleManager` class
- Handle `FlutterBluePlus` initialization
- Implement permission checking (Android location + BLE)
- Implement `scan()`, `stopScan()`, `connect()`, `disconnect()`, `discoverGatt()`, `createJsonConnection()`
- Map `flutter_blue_plus` scan results to `BleDeviceInfo`
- Wrap `BluetoothDevice` in `BleDeviceConnection`

#### `lib/ble/models/ble_device_info.dart`

- Implement `BleDeviceInfo` class with `id`, `name`, `rssi` fields

#### `lib/ble/models/ble_device_connection.dart`

- Implement `BleConnectionState` enum (connecting, connected, disconnected, error)
- Implement `BleDeviceConnection` class
- Maintain internal reference to `BluetoothDevice` from `flutter_blue_plus`
- Map connection state stream from `flutter_blue_plus` to `BleConnectionState`

#### `lib/ble/models/ble_gatt_info.dart`

- Implement `BleGattInfo` class with list of services
- Implement `GattServiceInfo` class with UUID and characteristics list
- Implement `GattCharInfo` class with UUID and capability flags (canRead, canWrite, canNotify)
- Map from `flutter_blue_plus` service/characteristic properties

#### `lib/ble/models/ble_json_connection.dart`

- Implement `BleJsonConnection` class
- Implement `sendJson(Map<String, dynamic>)` - encode to JSON string, convert to UTF-8 bytes, write to characteristic
- Implement `sendJsonString(String)` - convert string to UTF-8 bytes, write to characteristic
- Use `flutter_blue_plus` characteristic write API

#### `lib/ble/ble.dart` (export file)

- Export all public classes for easy importing

### 4. Create Simple Demo UI

Update `lib/main.dart` to include a basic demo that:

- Shows scan button and device list
- Allows device selection and connection
- Displays discovered services/characteristics
- Allows selection of writable characteristic
- Provides JSON input field and send button
- Demonstrates the complete workflow from the example usage

### 5. Error Handling

- Handle permission denials gracefully
- Surface connection errors via `BleConnectionState.error` and exceptions
- Handle write failures with appropriate exceptions
- Let OS handle pairing/bonding dialogs automatically

## Key Implementation Details

- Use `FlutterBluePlus.startScan()` and `FlutterBluePlus.scanResults` for scanning
- Use `BluetoothDevice.connect()` for connections
- Use `BluetoothDevice.discoverServices()` for GATT discovery
- Check characteristic properties (`properties.read`, `properties.write`, `properties.notify`) to determine capabilities
- Use `BluetoothCharacteristic.write()` with `withoutResponse: false` for JSON writes
- Convert JSON to UTF-8 bytes using `utf8.encode(jsonEncode(data))`

## Files to Create/Modify

**New Files:**

- `lib/ble/ble_manager.dart`
- `lib/ble/models/ble_device_info.dart`
- `lib/ble/models/ble_device_connection.dart`
- `lib/ble/models/ble_gatt_info.dart`
- `lib/ble/models/ble_json_connection.dart`
- `lib/ble/ble.dart`

**Modified Files:**

- `pubspec.yaml` - add `flutter_blue_plus: ^2.0.2`
- `android/app/src/main/AndroidManifest.xml` - add BLE and location permissions
- `lib/main.dart` - replace with demo UI