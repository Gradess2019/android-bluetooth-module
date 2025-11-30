import 'package:flutter/material.dart';

/// A reusable widget for BLE scan control buttons
class BleScanButtons extends StatelessWidget {
  /// Whether scanning is currently in progress
  final bool isScanning;

  /// Callback when start scan is pressed
  final VoidCallback onStartScan;

  /// Callback when stop scan is pressed
  final VoidCallback onStopScan;

  /// Label for the start scan button
  final String startLabel;

  /// Label for the stop scan button
  final String stopLabel;

  /// Layout direction (horizontal or vertical)
  final Axis layout;

  /// Spacing between buttons
  final double spacing;

  /// Custom style for the start button
  final ButtonStyle? startButtonStyle;

  /// Custom style for the stop button
  final ButtonStyle? stopButtonStyle;

  const BleScanButtons({
    super.key,
    required this.isScanning,
    required this.onStartScan,
    required this.onStopScan,
    this.startLabel = 'Start Scan',
    this.stopLabel = 'Stop Scan',
    this.layout = Axis.horizontal,
    this.spacing = 8.0,
    this.startButtonStyle,
    this.stopButtonStyle,
  });

  @override
  Widget build(BuildContext context) {
    final children = [
      Expanded(
        child: ElevatedButton(
          onPressed: isScanning ? null : onStartScan,
          style: startButtonStyle,
          child: Text(startLabel),
        ),
      ),
      SizedBox(
        width: layout == Axis.horizontal ? spacing : 0,
        height: layout == Axis.vertical ? spacing : 0,
      ),
      Expanded(
        child: ElevatedButton(
          onPressed: isScanning ? onStopScan : null,
          style: stopButtonStyle,
          child: Text(stopLabel),
        ),
      ),
    ];

    if (layout == Axis.horizontal) {
      return Row(children: children);
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
  }
}

