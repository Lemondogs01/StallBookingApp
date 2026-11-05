import 'package:flutter/material.dart';
import 'package:mfu_market/controller/booking_controller.dart';
import 'package:mfu_market/model/booking_model.dart';
import 'package:mfu_market/model/user_model.dart';
import 'package:mfu_market/theme.dart';
import 'package:mfu_market/utils.dart';
import 'package:mfu_market/views/pill.dart';

class MyBookingsView extends StatefulWidget {
  final UserModel user;

  const MyBookingsView({super.key, required this.user});

  @override
  State<MyBookingsView> createState() => _MyBookingsViewState();
}

class _MyBookingsViewState extends State<MyBookingsView> {
  final bookingController = BookingController();
  bool showUpcoming = true;
  late Future<List<BookingModel>> future;

  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  void loadBookings() {
    future = bookingController.fetchMyBookings(widget.user.id);
  }

  Future<void> cancelBooking(BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: Text('${booking.stallCode} on ${formatDay(booking.bookingDate)} '
            'will be released for other vendors.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep booking'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel booking',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    String message;
    try {
      await bookingController.cancelBooking(booking.id);
      message = 'Booking ${booking.stallCode} cancelled.';
    } catch (e) {
      message = cleanError(e);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    setState(loadBookings);
  }

  Widget buildBookingCard(BookingModel booking) {
    String? note;
    if (booking.status == 'rejected') note = 'Rejected by the market owner';
    if (booking.status == 'cancelled') note = 'You cancelled this booking';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(booking.stallCode,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
                statusPill(booking.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('${formatDay(booking.bookingDate)} · ${baht(booking.price)}',
                style: const TextStyle(fontSize: 18)),
            if (note != null) ...[
              const SizedBox(height: 10),
              Text(note,
                  style: const TextStyle(
                      fontSize: 16, color: AppColors.textMuted)),
            ],
            if (bookingController.canCancel(booking)) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => cancelBooking(booking),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                child: const Text('Cancel booking'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildBookingList() {
    return FutureBuilder<List<BookingModel>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Text(cleanError(snapshot.error!));
        }
        final now = today();
        final items = snapshot.data!
            .where((b) => showUpcoming
                ? !b.bookingDate.isBefore(now)
                : b.bookingDate.isBefore(now))
            .toList();
        items.sort((a, b) => showUpcoming
            ? a.bookingDate.compareTo(b.bookingDate)
            : b.bookingDate.compareTo(a.bookingDate));

        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(
              children: [
                Text(showUpcoming ? 'No upcoming bookings' : 'No past bookings',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                    showUpcoming
                        ? 'Find a stall and send a booking request.'
                        : 'Bookings from earlier sales dates show up here.',
                    style: const TextStyle(color: AppColors.textMuted)),
              ],
            ),
          );
        }
        return Column(children: [for (final b in items) buildBookingCard(b)]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        const Text('My bookings',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Upcoming')),
            ButtonSegment(value: false, label: Text('Past')),
          ],
          selected: {showUpcoming},
          showSelectedIcon: false,
          onSelectionChanged: (selection) =>
              setState(() => showUpcoming = selection.first),
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: AppColors.primary,
            selectedForegroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        buildBookingList(),
      ],
    );
  }
}
