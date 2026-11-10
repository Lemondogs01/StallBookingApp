import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../models/booking.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_card.dart';
import '../../widgets/booking_tile.dart';
import '../../widgets/page_header.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onSeeAllRequests});

  final VoidCallback onSeeAllRequests;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: adminStore,
      builder: (context, _) {
        final pending = adminStore.bookingsByStatus(BookingStatus.pending);
        final now = DateTime.now();
        final todayRevenue = adminStore.sum(adminStore.approvedOnDay(now));
        final monthRevenue =
            adminStore.sum(adminStore.approvedInMonth(now.year, now.month));

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const PageHeader(
              eyebrow: 'Admin overview',
              title: 'Run your market.',
              subtitle: 'Review requests and keep every stall up to date.',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.storefront_outlined,
                    label: 'Stalls',
                    value: '${adminStore.stalls.length}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    icon: Icons.hourglass_top,
                    label: 'Pending',
                    value: '${pending.length}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    icon: Icons.payments_outlined,
                    label: 'Today',
                    value: baht(todayRevenue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppCard(
              color: AppColors.green,
              bordered: false,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      color: AppColors.cream),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Revenue this month',
                        style: text.bodyMedium
                            ?.copyWith(color: AppColors.onGreenMuted)),
                  ),
                  Text(baht(monthRevenue),
                      style: text.titleLarge?.copyWith(
                          color: AppColors.cream,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AppCard(
              color: AppColors.amberSoft,
              bordered: false,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      color: AppColors.amberInk),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Slips waiting to be checked',
                        style: text.bodyMedium
                            ?.copyWith(color: AppColors.amberInk)),
                  ),
                  Text(baht(adminStore.pendingTotal),
                      style: text.titleLarge?.copyWith(
                          color: AppColors.amberInk,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text('Booking requests',
                      style: text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
                if (pending.length > 5)
                  TextButton(
                    onPressed: onSeeAllRequests,
                    child: Text('View all ${pending.length}'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (pending.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No pending requests')),
              )
            else
              for (final b in pending.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BookingTile(booking: b, showActions: true),
                ),
          ],
        );
      },
    );
  }
}
