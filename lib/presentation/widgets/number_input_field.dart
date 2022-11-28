import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberInputField extends StatelessWidget {
  const NumberInputField({
    super.key,
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (value) {
        if (value.isEmpty) {
          controller.text = '0';
          controller.selection =
              TextSelection.fromPosition(const TextPosition(offset: 1));
        } else if (value.startsWith('0')) {
          controller.text = value.substring(1);
          controller.selection =
              TextSelection.fromPosition(TextPosition(offset: value.length - 1));
        }
      },
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
    );
  }
}
