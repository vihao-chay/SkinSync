import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';

class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = value == null ? 'Chọn ngày sinh' : DateFormat('dd/MM/yyyy').format(value!);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedText, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                ],
              ),
            ),
            const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
