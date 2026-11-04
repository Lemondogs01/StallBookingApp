import 'package:flutter/material.dart';
import 'package:mfu_market/model/booking_model.dart';
import 'package:mfu_market/model/market_event.dart';
import 'package:mfu_market/model/stall_model.dart';
import 'package:mfu_market/theme.dart';
import 'package:mfu_market/utils.dart';
import 'package:mfu_market/views/widgets.dart';

class BookingConfirmedView extends StatelessWidget {
  final BookingModel booking;
  final MarketEvent event;
  final StallModel stall;

  const BookingConfirmedView({
    super.key,
    required this.booking,
    required this.event,
    required this.stall,
  });

  Widget detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: AppColors.text)),
          ),
        ],
      ),
    );
  }

  Widget block(String label, String title, String subtitle) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label),
          const SizedBox(height: 4),
          Text(title,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(subtitle,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final approved = booking.status == 'approved';
    final features = [
      stall.sizeLabel,
      if (stall.covered) 'Covered',
      if (stall.power) 'Power',
    ].join(' · ');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: "You're booked"),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: const Icon(Icons.check,
                          size: 28, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Your next chapter\nstarts at ${stall.label}.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800, height: 1.2)),
                  const SizedBox(height: 8),
                  const Text('You bring the good things. We power the rest.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MarketImage(
                          height: 110,
                          radius: 14,
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                    approved ? 'CONFIRMED' : 'PENDING APPROVAL',
                                    style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        color: AppColors.primary)),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(6, 12, 6, 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(event.name,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800)),
                              detailRow(Icons.calendar_today_outlined,
                                  '${formatFullDate(event.date)} · ${event.hours}'),
                              detailRow(Icons.location_on_outlined,
                                  '${event.venue}, ${event.area.split(', ').last}'),
                              const Divider(height: 24, color: AppColors.border),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  block('STALL', 'Stall ${stall.label}', features),
                                  block(
                                    'VENDOR',
                                    booking.businessName.isEmpty
                                        ? '—'
                                        : booking.businessName,
                                    booking.contactName,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  block('RESERVATION NUMBER', booking.reference,
                                      booking.status == 'approved'
                                          ? 'Approved'
                                          : 'Waiting for the owner'),
                                  block('TOTAL', money(booking.total),
                                      'Pay at the market'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Calendar sync is coming soon.')),
                    ),
                    icon: const Icon(Icons.event_available_outlined, size: 18),
                    label: const Text('Add to calendar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      minimumSize: const Size.fromHeight(46),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('See you at the market',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text(
                      'Arrive an hour early to set up and show your '
                      'reservation number at the entrance.',
                      style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        child: ElevatedButton(
          style: primaryButtonStyle(),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('View my bookings'),
        ),
      ),
    );
  }
}
