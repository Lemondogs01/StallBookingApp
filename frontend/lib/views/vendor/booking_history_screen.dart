import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/booking_controller.dart';
import '../../models/booking_model.dart';
import '../../models/stall_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'payment_upload_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BookingController>().loadBookings();
    });
  }

  Future<void> _cancel(BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking?'),
        backgroundColor: Colors.white,
        content: Text(
          booking.slipUrl != null
              ? 'A payment slip was submitted for stall ${booking.stallId}. Cancel this pending booking? Cancellation does not automatically refund your payment. Contact the market administrator about a refund.'
              : 'Do you want to cancel your booking for stall ${booking.stallId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Booking'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<BookingController>().cancelBooking(booking);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Booking cancelled.')));
      }
    } catch (_) {
      if (mounted) {
        final controller = context.read<BookingController>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              controller.errorMessage ?? 'Could not cancel this booking.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _pay(BookingModel booking) async {
    final stall = StallModel(
      id: booking.stallId,
      category: booking.category,
      price: booking.price,
      status: booking.status,
    );
    await showDialog<void>(
      context: context,
      builder: (_) =>
          PaymentUploadScreen(stall: stall, existingBooking: booking),
    );
  }

  void _showSlip(BookingModel booking) {
    final slipUrl = booking.slipUrl;
    if (slipUrl == null || slipUrl.isEmpty) return;
    final api = context.read<ApiService>();
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Payment Slip',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Flexible(
                child: Image.network(
                  api.resolveMediaUrl(slipUrl),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(28),
                    child: Text('Could not load the payment slip.'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingController>(
      builder: (context, controller, _) {
        final bookings = controller.bookings;
        if (controller.isLoadingBookings && bookings.isEmpty) {
          return const LoadingPanel();
        }
        return RefreshIndicator(
          onRefresh: controller.loadBookings,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const SectionTitle(
                'Booking History',
                subtitle: 'Review your bookings, payment slips, and status.',
              ),
              const SizedBox(height: 14),
              if (controller.errorMessage != null)
                ErrorBanner(
                  controller.errorMessage!,
                  onRetry: controller.loadBookings,
                ),
              if (bookings.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: _HistoryEmptyState(),
                )
              else
                for (final booking in bookings) ...[
                  _BookingCard(
                    booking: booking,
                    onCancel: () => _cancel(booking),
                    onPay: () => _pay(booking),
                    onEditSlip: () => _pay(booking),
                    onViewSlip: () => _showSlip(booking),
                  ),
                  const SizedBox(height: 11),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onCancel,
    required this.onPay,
    required this.onEditSlip,
    required this.onViewSlip,
  });

  final BookingModel booking;
  final VoidCallback onCancel;
  final VoidCallback onPay;
  final VoidCallback onEditSlip;
  final VoidCallback onViewSlip;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.bookingCode.isEmpty
                            ? 'Booking #${booking.id ?? '-'}'
                            : booking.bookingCode,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Stall ${booking.stallId} · ${booking.categoryLabel}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(booking.status),
              ],
            ),
            const SizedBox(height: 13),
            const Divider(height: 1),
            const SizedBox(height: 11),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: AppTheme.muted,
                ),
                const SizedBox(width: 7),
                Text(
                  formatDate(booking.bookingDate),
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
                const Spacer(),
                MoneyText(
                  booking.price,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (booking.status == 'pending') ...[
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  if (booking.slipUrl == null)
                    FilledButton.tonalIcon(
                      onPressed: onPay,
                      icon: const Icon(Icons.upload_file, size: 17),
                      label: const Text('Upload Slip'),
                    ),
                ],
              ),
            ],
            if (booking.slipUrl != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (booking.status == 'pending')
                    TextButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel_outlined, size: 17),
                      label: const Text('Cancel'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFB83A4B),
                      ),
                    ),
                  if (booking.status == 'pending')
                    TextButton.icon(
                      onPressed: onEditSlip,
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: const Text('Replace Slip'),
                    ),
                  TextButton.icon(
                    onPressed: onViewSlip,
                    icon: const Icon(Icons.receipt_long_outlined, size: 17),
                    label: const Text('View Slip'),
                  ),
                ],
              ),
            ],
            if (booking.status == 'pending' && booking.slipUrl == null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined, size: 17),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB83A4B),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.muted),
      SizedBox(height: 10),
      Text(
        'No bookings yet',
        style: TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w700),
      ),
      SizedBox(height: 4),
      Text(
        'Your bookings will appear here.',
        style: TextStyle(color: AppTheme.muted),
      ),
    ],
  );
}
