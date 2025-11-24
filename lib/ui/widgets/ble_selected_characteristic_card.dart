import 'package:flutter/material.dart';
import 'package:neo_bluetooth_module/ble/ble.dart';

/// A reusable widget for displaying selected characteristic information
class BleSelectedCharacteristicCard extends StatelessWidget {
  /// The selected service
  final GattServiceInfo service;

  /// The selected characteristic
  final GattCharInfo characteristic;

  /// Custom card background color
  final Color? backgroundColor;

  /// Custom card style
  final BleSelectedCharacteristicCardStyle? cardStyle;

  /// Custom header text style
  final TextStyle? headerStyle;

  /// Custom text style for UUIDs
  final TextStyle? uuidStyle;

  const BleSelectedCharacteristicCard({
    super.key,
    required this.service,
    required this.characteristic,
    this.backgroundColor,
    this.cardStyle,
    this.headerStyle,
    this.uuidStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = backgroundColor ?? Colors.green.shade50;

    return Card(
      color: cardStyle?.color ?? cardColor,
      elevation: cardStyle?.elevation,
      shape: cardStyle?.shape,
      child: Padding(
        padding: cardStyle?.padding ?? const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Characteristic',
              style: headerStyle ?? theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Service: ${service.uuid}',
              style: uuidStyle,
            ),
            Text(
              'Characteristic: ${characteristic.uuid}',
              style: uuidStyle,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom styling options for the selected characteristic card
class BleSelectedCharacteristicCardStyle {
  final Color? color;
  final double? elevation;
  final ShapeBorder? shape;
  final EdgeInsets? padding;

  const BleSelectedCharacteristicCardStyle({
    this.color,
    this.elevation,
    this.shape,
    this.padding,
  });
}

