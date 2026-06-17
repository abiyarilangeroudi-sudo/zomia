import 'package:flutter/material.dart';

class SelectFieldOption<T> {
  const SelectFieldOption({required this.value, required this.label});

  final T value;
  final String label;
}

class SelectField<T> extends StatelessWidget {
  const SelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final T? value;
  final List<SelectFieldOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: options
            .map(
              (option) => DropdownMenuItem<T>(
                value: option.value,
                child: Text(option.label),
              ),
            )
            .toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}
