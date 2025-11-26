import 'package:flutter/material.dart';
import 'package:neo_bluetooth_module/ble/ble.dart';

/// A reusable widget for displaying connected BLE device information
class BleConnectedDeviceCard extends StatelessWidget {
  /// The connected device information
  final BleDeviceConnection connection;

  /// Callback when disconnect button is pressed
  final VoidCallback onDisconnect;

  /// Custom disconnect button label
  final String disconnectLabel;

  /// Custom disconnect button style
  final ButtonStyle? disconnectButtonStyle;

  /// Custom card style
  final BleConnectedDeviceCardStyle? cardStyle;

  const BleConnectedDeviceCard({
    super.key,
    required this.connection,
    required this.onDisconnect,
    this.disconnectLabel = 'Disconnect',
    this.disconnectButtonStyle,
    this.cardStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
    );

    return Card(
      color: cardStyle?.color,
      elevation: cardStyle?.elevation,
      shape: cardStyle?.shape,
      child: Padding(
        padding: cardStyle?.padding ?? const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connected Device',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Name: ${connection.deviceInfo.name ?? "Unknown"}'),
            Text('ID: ${connection.deviceInfo.id}'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onDisconnect,
              style: disconnectButtonStyle ?? defaultButtonStyle,
              child: Text(disconnectLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom styling options for the connected device card
class BleConnectedDeviceCardStyle {
  final Color? color;
  final double? elevation;
  final ShapeBorder? shape;
  final EdgeInsets? padding;

  const BleConnectedDeviceCardStyle({
    this.color,
    this.elevation,
    this.shape,
    this.padding,
  });
}

