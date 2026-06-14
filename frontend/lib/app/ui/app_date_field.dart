import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';

class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: TextFormField(
        key: ValueKey('$label-${formatDate(value)}'),
        readOnly: true,
        initialValue: formatDate(value),
        onTap: () => _selectDate(context),
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            tooltip: 'Select date',
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () => _selectDate(context),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: BrandColors.orange,
              secondary: BrandColors.teal,
              surface: BrandColors.surface,
              onSurface: BrandColors.textPrimary,
            ),
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: BrandColors.surface,
              headerBackgroundColor: BrandColors.orange,
              headerForegroundColor: BrandColors.surface,
              todayBorder: BorderSide(color: BrandColors.teal),
              dayForegroundColor: WidgetStatePropertyAll(
                BrandColors.textPrimary,
              ),
              weekdayStyle: TextStyle(color: BrandColors.textSecondary),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: BrandColors.orange),
            ),
          ),
          child: child!,
        );
      },
    );
    if (selected != null) {
      onChanged(selected);
    }
  }

  static String formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
