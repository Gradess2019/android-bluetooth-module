import 'package:flutter/material.dart';

/// Status types for the BLE status card
enum BleStatusType {
  info,
  error,
  success,
  warning,
}

/// A reusable widget for displaying BLE status information
class BleStatusCard extends StatelessWidget {
  /// The status message to display
  final String statusMessage;

  /// The type of status (affects color)
  final BleStatusType? statusType;

  /// Whether to show "Status: " prefix
  final bool showPrefix;

  /// Custom card style
  final CardStyle? cardStyle;

  /// Custom text style
  final TextStyle? textStyle;

  const BleStatusCard({
    super.key,
    required this.statusMessage,
    this.statusType,
    this.showPrefix = true,
    this.cardStyle,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(theme);
    final displayText = showPrefix ? 'Status: $statusMessage' : statusMessage;

    return Card(
      color: cardStyle?.color ?? statusColor,
      elevation: cardStyle?.elevation,
      shape: cardStyle?.shape,
      child: Padding(
        padding: cardStyle?.padding ?? const EdgeInsets.all(16.0),
        child: Text(
          displayText,
          style: textStyle ?? theme.textTheme.titleMedium,
        ),
      ),
    );
  }

  Color? _getStatusColor(ThemeData theme) {
    if (statusType == null) return null;

    switch (statusType!) {
      case BleStatusType.error:
        return theme.colorScheme.errorContainer;
      case BleStatusType.success:
        return theme.colorScheme.primaryContainer;
      case BleStatusType.warning:
        return theme.colorScheme.tertiaryContainer;
      case BleStatusType.info:
        return null;
    }
  }
}

/// Custom styling options for the status card
class CardStyle {
  final Color? color;
  final double? elevation;
  final ShapeBorder? shape;
  final EdgeInsets? padding;

  const CardStyle({
    this.color,
    this.elevation,
    this.shape,
    this.padding,
  });
}

