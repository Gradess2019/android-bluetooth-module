import 'package:flutter/material.dart';
import 'package:neo_bluetooth_module/ble/ble.dart';
import '../widgets/ble_device_item.dart';

/// A reusable section for displaying a list of BLE devices
class BleDeviceListSection extends StatelessWidget {
  /// List of discovered devices
  final List<BleDeviceInfo> devices;

  /// ID of the currently connected device (to show checkmark)
  final String? connectedDeviceId;

  /// Callback when a device is tapped
  final void Function(BleDeviceInfo)? onDeviceTap;

  /// Custom header text (default: "Found Devices (X):")
  final String? headerText;

  /// Custom header text style
  final TextStyle? headerStyle;

  /// Spacing between header and device list
  final double headerSpacing;

  /// Spacing between device items
  final double itemSpacing;

  const BleDeviceListSection({
    super.key,
    required this.devices,
    this.connectedDeviceId,
    this.onDeviceTap,
    this.headerText,
    this.headerStyle,
    this.headerSpacing = 8.0,
    this.itemSpacing = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final displayHeader = headerText ?? 'Found Devices (${devices.length}):';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayHeader,
          style: headerStyle ?? theme.textTheme.titleMedium,
        ),
        SizedBox(height: headerSpacing),
        ...devices.map((device) {
          final isConnected = connectedDeviceId != null &&
              device.id == connectedDeviceId;
          return Padding(
            padding: EdgeInsets.only(bottom: itemSpacing),
            child: BleDeviceItem(
              device: device,
              isConnected: isConnected,
              onTap: onDeviceTap != null ? () => onDeviceTap!(device) : null,
            ),
          );
        }),
      ],
    );
  }
}

