import 'package:flutter/material.dart';
import '../widgets/ble_status_card.dart';
import '../widgets/ble_scan_buttons.dart';

/// A reusable section combining status card and scan buttons
class BleScanSection extends StatelessWidget {
  /// Current status message
  final String statusMessage;

  /// Whether scanning is in progress
  final bool isScanning;

  /// Callback when start scan is pressed
  final VoidCallback onStartScan;

  /// Callback when stop scan is pressed
  final VoidCallback onStopScan;

  /// Spacing between status card and buttons
  final double spacing;

  /// Custom status card style
  final BleStatusCardStyle? statusCardStyle;

  /// Custom scan button configuration
  final String? startLabel;
  final String? stopLabel;
  final ButtonStyle? startButtonStyle;
  final ButtonStyle? stopButtonStyle;

  const BleScanSection({
    super.key,
    required this.statusMessage,
    required this.isScanning,
    required this.onStartScan,
    required this.onStopScan,
    this.spacing = 16.0,
    this.statusCardStyle,
    this.startLabel,
    this.stopLabel,
    this.startButtonStyle,
    this.stopButtonStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BleStatusCard(
          statusMessage: statusMessage,
          cardStyle: statusCardStyle,
        ),
        SizedBox(height: spacing),
        BleScanButtons(
          isScanning: isScanning,
          onStartScan: onStartScan,
          onStopScan: onStopScan,
          startLabel: startLabel ?? 'Start Scan',
          stopLabel: stopLabel ?? 'Stop Scan',
          startButtonStyle: startButtonStyle,
          stopButtonStyle: stopButtonStyle,
        ),
      ],
    );
  }
}

