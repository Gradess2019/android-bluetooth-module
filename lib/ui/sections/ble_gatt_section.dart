import 'package:flutter/material.dart';
import 'package:neo_bluetooth_module/ble/ble.dart';
import '../widgets/ble_gatt_services_list.dart';

/// A reusable section for displaying GATT services and characteristics
class BleGattSection extends StatelessWidget {
  /// The GATT information containing services
  final BleGattInfo? gattInfo;

  /// Callback when a characteristic is selected
  final void Function(GattServiceInfo service, GattCharInfo characteristic)
      onCharacteristicSelected;

  /// Custom label for the select button
  final String? selectButtonLabel;

  /// Custom style for the select button
  final ButtonStyle? selectButtonStyle;

  /// Custom header text style
  final TextStyle? headerStyle;

  const BleGattSection({
    super.key,
    this.gattInfo,
    required this.onCharacteristicSelected,
    this.selectButtonLabel,
    this.selectButtonStyle,
    this.headerStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (gattInfo == null) {
      return const SizedBox.shrink();
    }

    return BleGattServicesList(
      gattInfo: gattInfo!,
      onCharacteristicSelected: onCharacteristicSelected,
      selectButtonLabel: selectButtonLabel ?? 'Select',
      selectButtonStyle: selectButtonStyle,
      headerStyle: headerStyle,
    );
  }
}

