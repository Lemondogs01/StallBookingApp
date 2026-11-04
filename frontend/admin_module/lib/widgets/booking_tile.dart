import 'package:flutter/material.dart';

import '../data/admin_store.dart';
import '../models/booking.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'app_card.dart';
import 'confirm_dialog.dart';
import 'status_chip.dart';

Future<void> approveBooking(BuildContext context, Booking b) async {
  final ok = await confirmAction(
    context,
    title: 'Approve booking?',
    message:
        'Stall ${b.stallCode} for ${b.userName} on ${fmtDate(b.bookingDate)}.',
    confirmLabel: 'Approve',
  );
  if (!ok || !context.mounted) return;
  final success = adminStore.approve(b.id);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(success
        ? 'Booking approved'
        : 'Cannot approve: stall ${b.stallCode} is already booked on this date'),
  ));
}

Future<void> rejectBooking(BuildContext context, Booking b) async {
  final ok = await confirmAction(
    context,
    title: 'Reject booking?',
    message:
        'Stall ${b.stallCode} for ${b.userName} on ${fmtDate(b.bookingDate)}.',
    confirmLabel: 'Reject',
  );
  if (!ok || !context.mounted) return;
  adminStore.reject(b.id);
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Booking rejected')));
}

class BookingTile extends StatelessWidget {
  const BookingTile({super.key, required this.booking, this.showActions = false});

  final Booking booking;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.greenSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(booking.stallCode,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.green)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.userName,
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
                Text(
                    '${fmtDate(booking.bookingDate)}  ·  ${baht(booking.price)}',
                    style: text.bodySmall?.copyWith(color: AppColors.muted)),
              ],
            ),
          ),
          if (showActions) ...[
            IconButton(
              tooltip: 'Approve',
              icon: const Icon(Icons.check_circle_outline, color: AppColors.green),
              onPressed: () => approveBooking(context, booking),
            ),
            IconButton(
              tooltip: 'Reject',
              icon: const Icon(Icons.cancel_outlined, color: AppColors.danger),
              onPressed: () => rejectBooking(context, booking),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: BookingStatusChip(booking.status),
            ),
        ],
      ),
    );
  }
}
