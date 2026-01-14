import 'package:flutter/material.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';

class CustomDropdownFormField<T> extends StatelessWidget {
  const CustomDropdownFormField({
    super.key,
    required this.value,
    required this.items,
    required this.labelText,
    this.onChanged,
    this.itemBuilder,
    this.validator,
  });
  final T? value;
  final List<T> items;
  final String labelText;
  final void Function(T?)? onChanged;
  final Widget Function(T)? itemBuilder;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.8,
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(labelText: labelText, border: const UnderlineInputBorder()),
        value: value,
        selectedItemBuilder: (BuildContext context) {
          return items.map<Widget>((T item) {
            return Text(item.toString());
          }).toList();
        },
        items: items.map((option) {
          return DropdownMenuItem<T>(
            value: option,
            child: _buildDropdownDecoration(
              child:
                  itemBuilder?.call(option) ?? MyCustomText(text: option.toString(), fontSize: 16),
              value: option,
              currentValue: value as T,
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator ?? (value) => value == null ? 'Please select an option' : null,
      ),
    );
  }

  Widget _buildDropdownDecoration({
    required Widget child,
    required T value,
    required T currentValue,
  }) {
    return Container(
      width: double.infinity,
      padding: const .all(10.0),
      decoration: BoxDecoration(
        color: value == currentValue ? Colors.grey.withOpacity(0.2) : Colors.transparent,
      ),
      child: child,
    );
  }
}
