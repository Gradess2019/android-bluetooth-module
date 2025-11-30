import 'package:flutter/material.dart';
import 'package:neo_bluetooth_module/ble/ble.dart';
import '../widgets/ble_selected_characteristic_card.dart';
import '../widgets/ble_json_text_field.dart';

/// A reusable section combining selected characteristic card and JSON text field
class BleJsonSection extends StatelessWidget {
  /// The selected service
  final GattServiceInfo? selectedService;

  /// The selected characteristic
  final GattCharInfo? selectedCharacteristic;

  /// The JSON connection (determines if section should be shown)
  final BleJsonConnection? jsonConnection;

  /// Controller for the JSON text field
  final TextEditingController jsonController;

  /// Callback when send button is pressed
  final VoidCallback onSend;

  /// Spacing between characteristic card and JSON field
  final double spacing;

  /// Custom styling for characteristic card
  final Color? characteristicCardColor;
  final BleSelectedCharacteristicCardStyle? characteristicCardStyle;

  /// Custom JSON field configuration
  final String? sectionLabel;
  final String? hintText;
  final int maxLines;
  final ButtonStyle? sendButtonStyle;

  const BleJsonSection({
    super.key,
    this.selectedService,
    this.selectedCharacteristic,
    this.jsonConnection,
    required this.jsonController,
    required this.onSend,
    this.spacing = 16.0,
    this.characteristicCardColor,
    this.characteristicCardStyle,
    this.sectionLabel,
    this.hintText,
    this.maxLines = 5,
    this.sendButtonStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (jsonConnection == null ||
        selectedService == null ||
        selectedCharacteristic == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BleSelectedCharacteristicCard(
          service: selectedService!,
          characteristic: selectedCharacteristic!,
          backgroundColor: characteristicCardColor,
          cardStyle: characteristicCardStyle,
        ),
        SizedBox(height: spacing),
        BleJsonTextField(
          controller: jsonController,
          onSend: onSend,
          sectionLabel: sectionLabel,
          hintText: hintText ?? 'Enter JSON data',
          maxLines: maxLines,
          sendButtonStyle: sendButtonStyle,
        ),
      ],
    );
  }
}

