import 'package:flutter/material.dart';

/// A reusable AppBar widget for BLE applications
class BleAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title to display
  final String title;

  /// Optional actions to display in the app bar
  final List<Widget>? actions;

  /// Custom background color
  final Color? backgroundColor;

  /// Custom foreground color
  final Color? foregroundColor;

  /// Whether to automatically use theme's inverse primary color
  final bool useInversePrimary;

  const BleAppBar({
    super.key,
    required this.title,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.useInversePrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ??
        (useInversePrimary ? theme.colorScheme.inversePrimary : null);

    return AppBar(
      title: Text(title),
      backgroundColor: bgColor,
      foregroundColor: foregroundColor,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

