import 'package:flutter/material.dart';
import 'package:neo_bluetooth_module/ble/ble.dart';

/// A reusable widget for displaying a BLE device in a list
class BleDeviceItem extends StatelessWidget {
  /// The device information to display
  final BleDeviceInfo device;

  /// Whether this device is currently connected
  final bool isConnected;

  /// Callback when the device is tapped
  final VoidCallback? onTap;

  /// Whether to show RSSI information
  final bool showRssi;

  /// Custom icon to show when connected (default: green checkmark)
  final Widget? connectedIcon;

  /// Custom text style for the device name
  final TextStyle? nameStyle;

  /// Custom text style for the device ID
  final TextStyle? idStyle;

  const BleDeviceItem({
    super.key,
    required this.device,
    this.isConnected = false,
    this.onTap,
    this.showRssi = true,
    this.connectedIcon,
    this.nameStyle,
    this.idStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          device.name ?? 'Unknown Device',
          style: nameStyle,
        ),
        subtitle: Text(
          _buildSubtitle(),
          style: idStyle,
        ),
        trailing: isConnected
            ? (connectedIcon ??
                const Icon(Icons.check_circle, color: Colors.green))
            : null,
        onTap: onTap,
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>['ID: ${device.id}'];
    if (showRssi) {
      parts.add('RSSI: ${device.rssi} dBm');
    }
    return parts.join('\n');
  }
}

