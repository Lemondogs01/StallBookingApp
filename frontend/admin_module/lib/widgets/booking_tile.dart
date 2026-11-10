import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'app_card.dart';
import 'payment_review_sheet.dart';
import 'status_chip.dart';

/// Tapping a tile (or "Review") opens the payment slip check.
/// Approve / reject now happen there, after the admin has seen the slip.
class BookingTile extends StatelessWidget {
  const BookingTile({super.key, required this.booking, this.showActions = false});

  final Booking booking;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => showPaymentReview(context, booking),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
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
                      style:
                          text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                  Text(
                      '${fmtDate(booking.bookingDate)}  ·  ${baht(booking.price)}',
                      style: text.bodySmall?.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
            if (showActions)
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  textStyle:
                      const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                onPressed: () => showPaymentReview(context, booking),
                child: const Text('Review'),
              )
            else
              BookingStatusChip(booking.status),
          ],
        ),
      ),
    );
  }
}
