import 'package:flutter/material.dart';
import 'package:mfu_market/theme.dart';

class Pill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const Pill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

Widget statusPill(String status) {
  switch (status) {
    case 'approved':
      return const Pill(
          label: 'Approved',
          background: AppColors.successBg,
          foreground: AppColors.success);
    case 'rejected':
      return const Pill(
          label: 'Rejected',
          background: AppColors.dangerBg,
          foreground: AppColors.danger);
    case 'cancelled':
      return const Pill(
          label: 'Cancelled',
          background: AppColors.neutralBg,
          foreground: AppColors.neutral);
    default:
      return const Pill(
          label: 'Pending',
          background: AppColors.warningBg,
          foreground: AppColors.warning);
  }
}
