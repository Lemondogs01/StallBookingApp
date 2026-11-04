import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../models/booking.dart';
import '../../theme/app_theme.dart';
import '../../widgets/booking_tile.dart';
import '../../widgets/page_header.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: adminStore,
      builder: (context, _) {
        return DefaultTabController(
          length: BookingStatus.values.length,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: PageHeader(
                  eyebrow: 'Bookings',
                  title: 'Booking requests.',
                  subtitle: 'Approve or reject vendor requests.',
                ),
              ),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.green,
                unselectedLabelColor: AppColors.muted,
                indicatorColor: AppColors.green,
                dividerColor: AppColors.border,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                tabs: [
                  for (final s in BookingStatus.values)
                    Tab(text: '${s.label} (${adminStore.countByStatus(s)})'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    for (final s in BookingStatus.values) _BookingList(status: s),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({required this.status});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final items = adminStore.bookingsByStatus(status);
    if (items.isEmpty) {
      return Center(child: Text('No ${status.label.toLowerCase()} bookings'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => BookingTile(
        booking: items[i],
        showActions: status == BookingStatus.pending,
      ),
    );
  }
}
