import 'package:flutter/material.dart';

/// A reusable widget for JSON input and sending
class BleJsonTextField extends StatelessWidget {
  /// Controller for the text field
  final TextEditingController controller;

  /// Callback when send button is pressed
  final VoidCallback onSend;

  /// Custom label for the send button
  final String sendButtonLabel;

  /// Custom label for the text field section
  final String? sectionLabel;

  /// Custom hint text for the text field
  final String hintText;

  /// Number of lines for the text field
  final int maxLines;

  /// Custom style for the send button
  final ButtonStyle? sendButtonStyle;

  /// Custom style for the section label
  final TextStyle? sectionLabelStyle;

  /// Custom decoration for the text field
  final InputDecoration? decoration;

  const BleJsonTextField({
    super.key,
    required this.controller,
    required this.onSend,
    this.sendButtonLabel = 'Send JSON',
    this.sectionLabel,
    this.hintText = 'Enter JSON data',
    this.maxLines = 5,
    this.sendButtonStyle,
    this.sectionLabelStyle,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultDecoration = InputDecoration(
      border: const OutlineInputBorder(),
      hintText: hintText,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sectionLabel != null) ...[
          Text(
            sectionLabel!,
            style: sectionLabelStyle ?? theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: decoration ?? defaultDecoration,
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: onSend,
          style: sendButtonStyle,
          child: Text(sendButtonLabel),
        ),
      ],
    );
  }
}

