import 'package:flutter/material.dart';

import '../data/admin_store.dart';
import '../models/booking.dart';
import '../models/payment.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'app_card.dart';
import 'status_chip.dart';

const _rejectReasons = [
  'Invalid or unreadable slip',
  'Amount does not match',
  'Slip already used',
];

/// Bottom sheet where the admin checks a payment slip, then approves or
/// rejects the booking. Also shows read-only details for finished payments.
Future<void> showPaymentReview(BuildContext context, Booking booking) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PaymentReview(bookingId: booking.id),
  );
}

class _PaymentReview extends StatelessWidget {
  const _PaymentReview({required this.bookingId});
  final int bookingId;

  void _approve(BuildContext context, Booking b) {
    final messenger = ScaffoldMessenger.of(context);
    final ok = adminStore.approve(b.id);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(
      content: Text(ok
          ? 'Payment verified, booking approved'
          : 'Cannot approve: stall ${b.stallCode} is already booked on this date'),
    ));
  }

  Future<void> _reject(BuildContext context, Booking b) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Reject payment'),
        children: [
          for (final r in _rejectReasons)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, r),
              child: Text(r),
            ),
        ],
      ),
    );
    if (reason == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    adminStore.reject(b.id, reason: reason);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text('Booking rejected: $reason')));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: adminStore,
      builder: (context, _) {
        final booking = adminStore.bookingById(bookingId);
        final payment = adminStore.paymentFor(bookingId);
        if (booking == null || payment == null) {
          return const SizedBox(
              height: 120, child: Center(child: Text('Payment not found')));
        }
        final canReview = booking.status == BookingStatus.pending &&
            payment.status == PaymentStatus.pending;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Check payment',
                        style: text.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  PaymentStatusChip(payment.status),
                ],
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: [
                    _InfoRow('Booking', bookingCode(booking.id)),
                    _InfoRow('Vendor', booking.userName),
                    _InfoRow('Stall', booking.stallCode),
                    _InfoRow('Sales date', fmtDate(booking.bookingDate)),
                    _InfoRow('Method', payment.method.label),
                    const Divider(height: 20, color: AppColors.border),
                    _InfoRow('Amount', baht(payment.amount), bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SlipPreview(payment: payment),
              const SizedBox(height: 12),
              if (payment.status == PaymentStatus.failed &&
                  payment.rejectReason != null)
                Text('Rejected: ${payment.rejectReason}',
                    style: text.bodyMedium?.copyWith(color: AppColors.danger)),
              if (payment.status == PaymentStatus.paid && payment.paidAt != null)
                Text('Verified and paid on ${fmtDateTime(payment.paidAt!)}',
                    style: text.bodyMedium?.copyWith(color: AppColors.muted)),
              if (payment.status == PaymentStatus.refunded)
                Text(
                    'The vendor cancelled this booking. Refund ${baht(payment.amount)} via PromptPay.',
                    style: text.bodyMedium?.copyWith(color: AppColors.muted)),
              if (canReview) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          minimumSize: const Size(64, 52),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        onPressed: () => _reject(context, booking),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _approve(context, booking),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: text.bodyMedium?.copyWith(color: AppColors.muted)),
          const Spacer(),
          Text(value,
              style: (bold ? text.titleMedium : text.bodyMedium)?.copyWith(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Mock slip. In Sprint 3 this shows the image the vendor uploaded.
/// The header and colour follow the payment status so the slip never says
/// "successful" when the admin has rejected it.
class _SlipPreview extends StatelessWidget {
  const _SlipPreview({required this.payment});
  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final Color background;
    final Color foreground;
    final IconData icon;
    final String title;
    switch (payment.status) {
      case PaymentStatus.pending:
        background = AppColors.amberSoft;
        foreground = AppColors.amberInk;
        icon = Icons.hourglass_top;
        title = 'Slip uploaded, not checked yet';
      case PaymentStatus.paid:
        background = AppColors.greenSoft;
        foreground = AppColors.green;
        icon = Icons.check_circle;
        title = 'Slip verified';
      case PaymentStatus.failed:
        background = AppColors.dangerSoft;
        foreground = AppColors.danger;
        icon = Icons.cancel;
        title = 'Slip rejected';
      case PaymentStatus.refunded:
        background = AppColors.beige;
        foreground = AppColors.muted;
        icon = Icons.undo;
        title = 'Slip refunded';
    }

    return AppCard(
      color: background,
      bordered: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800, color: foreground)),
              ),
              Text('Slip preview (mock)',
                  style: text.labelSmall?.copyWith(color: AppColors.muted)),
            ],
          ),
          const Divider(height: 20, color: AppColors.border),
          _InfoRow('Amount', baht(payment.amount)),
          _InfoRow('To',
              '${payment.method.label} ${formatPromptPayId(adminStore.promptPayId)}'),
          _InfoRow('Account', adminStore.accountName),
          _InfoRow('Reference', payment.reference),
          _InfoRow('Date', fmtDateTime(payment.createdAt)),
        ],
      ),
    );
  }
}
