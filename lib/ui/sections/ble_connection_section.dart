import 'package:flutter/material.dart';
import 'package:neo_bluetooth_module/ble/ble.dart';
import '../widgets/ble_connected_device_card.dart';

/// A reusable section for displaying connected device information
class BleConnectionSection extends StatelessWidget {
  /// The connected device connection
  final BleDeviceConnection? connection;

  /// Callback when disconnect button is pressed
  final VoidCallback onDisconnect;

  /// Custom disconnect button label
  final String? disconnectLabel;

  /// Custom disconnect button style
  final ButtonStyle? disconnectButtonStyle;

  /// Custom card style (using the one from widget)
  final BleConnectedDeviceCardStyle? cardStyle;

  const BleConnectionSection({
    super.key,
    this.connection,
    required this.onDisconnect,
    this.disconnectLabel,
    this.disconnectButtonStyle,
    this.cardStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (connection == null) {
      return const SizedBox.shrink();
    }

    return BleConnectedDeviceCard(
      connection: connection!,
      onDisconnect: onDisconnect,
      disconnectLabel: disconnectLabel ?? 'Disconnect',
      disconnectButtonStyle: disconnectButtonStyle,
      cardStyle: cardStyle,
    );
  }
}

