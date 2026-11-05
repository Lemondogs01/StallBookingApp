import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/stall.dart';
import '../theme/app_theme.dart';

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.background, this.foreground);
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground, fontWeight: FontWeight.w600)),
    );
  }
}

class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip(this.status, {super.key});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case BookingStatus.pending:
        return _Pill(status.label, AppColors.amberSoft, AppColors.amberInk);
      case BookingStatus.approved:
        return _Pill(status.label, AppColors.greenSoft, AppColors.green);
      case BookingStatus.rejected:
        return _Pill(status.label, AppColors.dangerSoft, AppColors.danger);
      case BookingStatus.cancelled:
        return _Pill(status.label, AppColors.beige, AppColors.muted);
    }
  }
}

class StallStatusChip extends StatelessWidget {
  const StallStatusChip(this.status, {super.key});
  final StallStatus status;

  @override
  Widget build(BuildContext context) {
    return status == StallStatus.available
        ? _Pill(status.label, AppColors.greenSoft, AppColors.green)
        : _Pill(status.label, AppColors.beige, AppColors.muted);
  }
}
