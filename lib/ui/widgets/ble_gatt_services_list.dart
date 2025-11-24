import 'package:flutter/material.dart';
import 'package:neo_bluetooth_module/ble/ble.dart';

/// A reusable widget for displaying GATT services and characteristics
class BleGattServicesList extends StatelessWidget {
  /// The GATT information containing services
  final BleGattInfo gattInfo;

  /// Callback when a characteristic is selected
  final void Function(GattServiceInfo service, GattCharInfo characteristic)
      onCharacteristicSelected;

  /// Custom label for the select button
  final String selectButtonLabel;

  /// Custom style for the select button
  final ButtonStyle? selectButtonStyle;

  /// Custom header text style
  final TextStyle? headerStyle;

  const BleGattServicesList({
    super.key,
    required this.gattInfo,
    required this.onCharacteristicSelected,
    this.selectButtonLabel = 'Select',
    this.selectButtonStyle,
    this.headerStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GATT Services (${gattInfo.services.length}):',
          style: headerStyle ?? theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...(gattInfo.services.map((service) => Card(
              child: ExpansionTile(
                title: Text('Service: ${service.uuid}'),
                subtitle: Text(
                    '${service.characteristics.length} characteristics'),
                children: [
                  ...(service.characteristics.map((char) => ListTile(
                        title: Text('Characteristic: ${char.uuid}'),
                        subtitle: Text(
                            'Read: ${char.canRead}, Write: ${char.canWrite}, Notify: ${char.canNotify}'),
                        trailing: char.canWrite
                            ? ElevatedButton(
                                onPressed: () =>
                                    onCharacteristicSelected(service, char),
                                style: selectButtonStyle,
                                child: Text(selectButtonLabel),
                              )
                            : null,
                      ))),
                ],
              ),
            ))),
      ],
    );
  }
}

