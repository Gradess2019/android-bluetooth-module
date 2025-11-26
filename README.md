# neo_bluetooth_module

A Flutter library for Bluetooth Low Energy (BLE) device communication with JSON support, including UI components and connection management.

## Features

- **BLE Device Scanning**: Discover nearby BLE devices with signal strength information
- **Device Connection Management**: Connect, disconnect, and monitor connection state
- **GATT Discovery**: Automatically discover services and characteristics
- **JSON Communication**: Send JSON data over BLE with automatic chunking for large messages
- **UI Components**: Pre-built widgets and sections for quick BLE integration
- **Connection Flow**: Complete ready-to-use flow widget for device connection and JSON communication
- **Permission Handling**: Built-in permission checking and requesting for Android
- **Connection Configuration**: Configurable MTU, auto-connect, and bonding settings

## Installation

### Option 1: Git Dependency (Recommended for GitHub)

Add this package to your `pubspec.yaml` as a git dependency:

```yaml
dependencies:
  neo_bluetooth_module:
    git:
      url: https://github.com/Gradess2019/android-bluetooth-module.git
      ref: master  # or use a specific tag/commit
```

### Option 2: Local Path Dependency

Alternatively, you can use a local path dependency:

```yaml
dependencies:
  neo_bluetooth_module:
    path: ../path/to/neo_bluetooth_module
```

Then run:

```bash
flutter pub get
```

## Requirements

- Flutter SDK: `^3.7.2`
- Android: Minimum SDK 21 (Android 5.0)
- iOS: iOS 12.0 or later
- Windows: Windows 10 or later

## Platform Setup

### Android

Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- BLE Permissions -->
    <uses-permission android:name="android.permission.BLUETOOTH" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <!-- Rest of your manifest -->
</manifest>
```

**Note**: For Android 12+ (API 31+), `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT` are required. The library handles permission requests automatically.

### iOS

Add the following to your `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to connect to devices</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth to connect to devices</string>
```

### Windows

No additional setup required. The library uses the Windows Bluetooth APIs through `flutter_blue_plus`.

## Quick Start

### Basic Usage

```dart
import 'package:neo_bluetooth_module/ble/ble.dart';

// Create a BLE manager
final manager = BleManager();

// Check and request permissions
final hasPermissions = await manager.checkPermissions();
if (!hasPermissions) {
  print('Permissions not granted');
  return;
}

// Start scanning
await manager.scan();

// Listen for discovered devices
manager.scanResults.listen((device) {
  print('Found device: ${device.name ?? device.id}');
});

// Stop scanning
await manager.stopScan();
```

### Connecting to a Device

```dart
// Connect to a discovered device
final connection = await manager.connect(device);

// Listen to connection state changes
connection.connectionState.listen((state) {
  switch (state) {
    case BleConnectionState.connected:
      print('Connected!');
      break;
    case BleConnectionState.disconnected:
      print('Disconnected');
      break;
    // ... other states
  }
});

// Discover GATT services
final gattInfo = await manager.discoverGatt(connection);
print('Found ${gattInfo.services.length} services');

// Disconnect
await manager.disconnect(connection);
```

### Sending JSON Data

```dart
// Create a JSON connection for a specific service and characteristic
final jsonConnection = await manager.createJsonConnection(
  connection,
  serviceUuid,
  characteristicUuid,
);

// Send JSON data
await jsonConnection.sendJson({
  'command': 'setAnimation',
  'name': 'wave',
  'speed': 0.7,
});

// Or send a JSON string directly
await jsonConnection.sendJsonString('{"command": "stop"}');
```

### Using UI Components

```dart
import 'package:neo_bluetooth_module/ui/ui.dart';

// Use pre-built sections
BleScanSection(
  statusMessage: 'Ready to scan',
  isScanning: false,
  onStartScan: () async {
    await manager.scan();
  },
  onStopScan: () async {
    await manager.stopScan();
  },
)

// Use the complete connection flow
BleJsonConnectionFlow(
  appBarTitle: 'Connect to Device',
  initialJsonText: '{"command": "test"}',
  onComplete: (result) {
    print('Connection result: ${result.jsonConnection}');
  },
  onCancel: () {
    print('Flow cancelled');
  },
)
```

## API Documentation

### Core Classes

#### `BleManager`

Main class for managing BLE operations.

**Properties:**
- `bool isScanning`: Whether a scan is currently in progress
- `Stream<BleDeviceInfo> scanResults`: Stream of discovered devices during scanning

**Methods:**
- `Future<bool> checkPermissions()`: Check and request required permissions
- `Future<void> scan()`: Start scanning for BLE devices
- `Future<void> stopScan()`: Stop scanning
- `Future<BleDeviceConnection> connect(BleDeviceInfo device, {BleConnectionConfig? config})`: Connect to a device
- `Future<void> disconnect(BleDeviceConnection connection)`: Disconnect from a device
- `Future<BleGattInfo> discoverGatt(BleDeviceConnection connection)`: Discover GATT services and characteristics
- `Future<BleJsonConnection> createJsonConnection(BleDeviceConnection connection, String serviceUuid, String characteristicUuid, {int? mtuPayload})`: Create a JSON connection
- `void dispose()`: Clean up resources

#### `BleDeviceInfo`

Information about a discovered BLE device.

**Properties:**
- `String id`: Device identifier (MAC address on Android, UUID on iOS)
- `String? name`: Device name (may be null if not advertised)
- `int rssi`: Signal strength in dBm

#### `BleDeviceConnection`

Represents a connection to a BLE device.

**Properties:**
- `BleDeviceInfo deviceInfo`: Information about the connected device
- `Stream<BleConnectionState> connectionState`: Stream of connection state changes

#### `BleConnectionState`

Enum representing connection states:
- `connecting`: Connection in progress
- `connected`: Successfully connected
- `disconnecting`: Disconnection in progress
- `disconnected`: Not connected
- `error`: Connection error occurred

#### `BleGattInfo`

Complete GATT information for a device.

**Properties:**
- `List<GattServiceInfo> services`: List of all discovered services

#### `GattServiceInfo`

Information about a GATT service.

**Properties:**
- `String uuid`: Service UUID
- `List<GattCharInfo> characteristics`: List of characteristics in this service

#### `GattCharInfo`

Information about a GATT characteristic.

**Properties:**
- `String uuid`: Characteristic UUID
- `bool canRead`: Whether this characteristic can be read
- `bool canWrite`: Whether this characteristic can be written to
- `bool canNotify`: Whether this characteristic supports notifications

#### `BleJsonConnection`

Connection for sending JSON data over BLE.

**Methods:**
- `Future<void> sendJson(Map<String, dynamic> json)`: Send a JSON object
- `Future<void> sendJsonString(String jsonString)`: Send a JSON string

**Features:**
- Automatic chunking for messages larger than MTU payload size
- UTF-8 encoding
- Newline termination for message boundaries

#### `BleConnectionConfig`

Configuration for BLE device connection.

**Properties:**
- `String? license`: License key for flutter_blue_plus (optional, for commercial use)
- `int? mtu`: Maximum Transmission Unit to negotiate during connection
- `bool autoConnect`: Whether to automatically reconnect if connection is lost (default: `true`)
- `bool requireBonding`: Whether bonding/pairing is required (default: `true`)
- `bool bondingAndroidOnly`: Whether bonding should only be attempted on Android (default: `true`)

**Constants:**
- `BleConnectionConfig.defaultConfig`: Default configuration with sensible defaults

### UI Components

#### Widgets

- `BleAppBar`: Custom app bar for BLE screens
- `BleDeviceItem`: Widget for displaying a device in a list
- `BleScanButtons`: Buttons for starting/stopping scans
- `BleStatusCard`: Card displaying connection status
- `BleConnectedDeviceCard`: Card showing connected device information
- `BleGattServicesList`: List widget for displaying GATT services
- `BleSelectedCharacteristicCard`: Card showing selected characteristic
- `BleJsonTextField`: Text field for entering JSON data

#### Sections

- `BleScanSection`: Complete section for device scanning
- `BleDeviceListSection`: Section displaying list of discovered devices
- `BleConnectionSection`: Section showing connection status and disconnect button
- `BleGattSection`: Section for displaying and selecting GATT services/characteristics
- `BleJsonSection`: Section for sending JSON data

#### Flow Components

- `BleJsonConnectionFlow`: Complete, reusable flow widget for BLE connection and JSON communication
- `BleJsonConnectionResult`: Result object returned by the flow

### Error Handling

The library provides specific error types:

- `BleError`: Base class for BLE errors
- `BlePermissionError`: Permission-related errors
- `BleUnsupportedError`: Bluetooth not supported on device
- `BleWriteError`: Errors during data writing

## Usage Examples

### Example 1: Basic Scanning and Connection

```dart
final manager = BleManager();

// Request permissions
if (!await manager.checkPermissions()) {
  return;
}

// Start scanning
await manager.scan();

// Listen for devices
manager.scanResults.listen((device) async {
  if (device.name?.contains('MyDevice') ?? false) {
    await manager.stopScan();
    
    // Connect
    final connection = await manager.connect(device);
    print('Connected to ${device.name}');
    
    // Use connection...
  }
});
```

### Example 2: Using Connection Configuration

```dart
final config = BleConnectionConfig(
  mtu: 512,  // Request larger MTU for bigger payloads
  autoConnect: true,
  requireBonding: false,
);

final connection = await manager.connect(device, config: config);
```

### Example 3: Complete Flow with UI

```dart
// Navigate to the connection flow
final result = await BleJsonConnectionFlow.navigate(
  context,
  appBarTitle: 'Connect to Device',
  initialJsonText: '{"command": "start"}',
);

if (result != null && result.isSuccess) {
  // Use the connection
  await result.jsonConnection?.sendJson({'command': 'next'});
}
```

### Example 4: Custom UI with Sections

```dart
Column(
  children: [
    BleScanSection(
      statusMessage: statusMessage,
      isScanning: isScanning,
      onStartScan: _startScan,
      onStopScan: _stopScan,
    ),
    BleDeviceListSection(
      devices: devices,
      connectedDeviceId: connection?.deviceInfo.id,
      onDeviceTap: (device) => _connectToDevice(device),
    ),
    if (connection != null)
      BleConnectionSection(
        connection: connection,
        onDisconnect: _disconnect,
      ),
  ],
)
```

## Dependencies

- `flutter_blue_plus: 1.30.0` - BLE functionality (minimum version required for connect API)
- `permission_handler: ^11.3.1` - Permission handling

## Example App

See the `example/` directory for a complete example app demonstrating all features of the library.

To run the example:

```bash
cd example
flutter pub get
flutter run
```

## License

This package is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

Copyright (c) 2025 Gradess Games

## Contributing

This repository is read-only and publicly visible for reference purposes. This library is maintained by Gradess Games. For issues or feature requests, please contact the maintainers.
