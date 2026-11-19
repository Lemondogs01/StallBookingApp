import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../models/admin_analytics_model.dart';
import '../../models/booking_model.dart';
import '../../models/stall_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _requestedLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requestedLoad) {
      _requestedLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<AdminController>().loadDashboard();
      });
    }
  }

  Future<void> _verify(BookingModel booking, bool approve) async {
    try {
      await context.read<AdminController>().verifyBooking(
        booking,
        approve: approve,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Booking approved.' : 'Booking rejected.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        final controller = context.read<AdminController>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              controller.errorMessage ?? 'Could not review this booking.',
            ),
          ),
        );
      }
    }
  }

  void _showMonthlyBreakdown(
    AdminController controller, {
    required bool pending,
  }) {
    final months = List.generate(
      12,
      (index) => DateTime(
        controller.selectedDate.year,
        controller.selectedDate.month - 11 + index,
        1,
      ),
    );
    final revenueByMonth = <String, double>{
      for (final month in months) _monthKey(month): 0,
    };

    if (pending) {
      for (final booking in controller.pendingBookings) {
        final key = _monthKey(booking.bookingDate);
        if (revenueByMonth.containsKey(key)) {
          revenueByMonth[key] = revenueByMonth[key]! + booking.price;
        }
      }
    } else {
      for (final entry in controller.analytics?.monthlyBreakdown ?? const []) {
        final key = _monthKey(entry.month);
        if (revenueByMonth.containsKey(key)) {
          revenueByMonth[key] = entry.revenue;
        }
      }
    }

    final maximum = revenueByMonth.values.fold<double>(
      0,
      (value, revenue) => revenue > value ? revenue : value,
    );
    final total = revenueByMonth.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          child: Padding(
            padding: const EdgeInsets.all(19),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pending
                            ? 'Monthly Pending Revenue'
                            : 'Monthly Approved Revenue',
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '12 months through ${formatDate(controller.selectedDate)}',
                    style: const TextStyle(color: AppTheme.muted, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: months.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final month = months[index];
                      final revenue = revenueByMonth[_monthKey(month)] ?? 0;
                      return Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9F8),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: const Color(0xFFE8EEEB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(formatMonth(month))),
                                MoneyText(
                                  revenue,
                                  style: TextStyle(
                                    color: pending
                                        ? const Color(0xFFB77900)
                                        : AppTheme.green,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            LinearProgressIndicator(
                              value: maximum <= 0
                                  ? 0
                                  : (revenue / maximum).clamp(0.0, 1.0),
                              color: pending
                                  ? const Color(0xFFF59E0B)
                                  : AppTheme.green,
                              backgroundColor: const Color(0xFFE2E8E5),
                              minHeight: 7,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pending ? 'Pending total' : 'Approved total',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    MoneyText(
                      total,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _monthKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

  void _reviewBooking(BookingModel booking) {
    final slipUrl = booking.slipUrl;
    final api = context.read<ApiService>();
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Review Booking',
                        style: TextStyle(
                          color: AppTheme.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9F8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8EEEB)),
                  ),
                  child: Column(
                    children: [
                      _BookingInfoRow(
                        label: 'Booking date',
                        value: formatDate(booking.bookingDate),
                        valueColor: AppTheme.green,
                      ),
                      _BookingInfoRow(
                        label: 'Booking code',
                        value: booking.bookingCode.isEmpty
                            ? '#${booking.id ?? '-'}'
                            : booking.bookingCode,
                      ),
                      _BookingInfoRow(
                        label: 'Shop',
                        value: booking.shopName ?? 'Unavailable',
                      ),
                      _BookingInfoRow(
                        label: 'Contact',
                        value: booking.realName ?? 'Unavailable',
                      ),
                      _BookingInfoRow(
                        label: 'Phone',
                        value: booking.phone ?? 'Unavailable',
                      ),
                      const Divider(height: 17),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Amount paid',
                              style: TextStyle(color: AppTheme.muted),
                            ),
                          ),
                          MoneyText(
                            booking.paidAmount ?? booking.price,
                            style: const TextStyle(
                              color: AppTheme.green,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (slipUrl == null || slipUrl.isEmpty)
                  Container(
                    height: 190,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'No payment slip was uploaded.',
                      style: TextStyle(color: AppTheme.muted),
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      api.resolveMediaUrl(slipUrl),
                      height: 260,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Container(
                        height: 190,
                        alignment: Alignment.center,
                        color: const Color(0xFFF1F5F3),
                        child: const Text(
                          'Could not load the payment slip.',
                          style: TextStyle(color: AppTheme.muted),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _verify(booking, false);
                        },
                        icon: const Icon(Icons.close, size: 17),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB83A4B),
                          minimumSize: const Size.fromHeight(46),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: slipUrl == null || slipUrl.isEmpty
                            ? null
                            : () {
                                Navigator.pop(context);
                                _verify(booking, true);
                              },
                        icon: const Icon(Icons.check, size: 17),
                        label: const Text('Approve'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.green,
                          minimumSize: const Size.fromHeight(46),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showApprovedStallDetails(StallModel stall) {
    final booking = stall.booking;
    if (booking == null) return;
    final api = context.read<ApiService>();

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Approved Stall ${stall.id}',
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9F8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8EEEB)),
                  ),
                  child: Column(
                    children: [
                      _BookingInfoRow(
                        label: 'Booking code',
                        value: booking.bookingCode ?? '#${booking.id ?? '-'}',
                      ),
                      _BookingInfoRow(
                        label: 'Booking date',
                        value: booking.bookingDate == null
                            ? 'Unavailable'
                            : formatDate(booking.bookingDate!),
                        valueColor: AppTheme.green,
                      ),
                      _BookingInfoRow(
                        label: 'Category',
                        value: stall.categoryLabel,
                      ),
                      _BookingInfoRow(
                        label: 'Shop',
                        value: booking.shopName ?? 'Unavailable',
                      ),
                      _BookingInfoRow(
                        label: 'Vendor',
                        value: booking.vendorName ?? 'Unavailable',
                      ),
                      _BookingInfoRow(
                        label: 'Phone',
                        value: booking.vendorPhone ?? 'Unavailable',
                      ),
                      const Divider(height: 17),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Amount paid',
                              style: TextStyle(color: AppTheme.muted),
                            ),
                          ),
                          MoneyText(
                            booking.paidAmount ?? booking.price ?? stall.price,
                            style: const TextStyle(
                              color: AppTheme.green,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (booking.slipUrl?.isNotEmpty == true) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      api.resolveMediaUrl(booking.slipUrl!),
                      height: 260,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Container(
                        height: 190,
                        alignment: Alignment.center,
                        color: const Color(0xFFF1F5F3),
                        child: const Text(
                          'Could not load the payment slip.',
                          style: TextStyle(color: AppTheme.muted),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.green,
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminController>(
      builder: (context, controller, _) {
        final analytics = controller.analytics;
        final pendingRevenue = controller.pendingBookings.fold<double>(
          0,
          (sum, booking) => sum + booking.price,
        );
        final dailyTrend =
            analytics?.dailyTrendCenteredOn(controller.selectedDate) ??
            const <DailyRevenue>[];
        final dailyMaximum = dailyTrend.fold<double>(
          0,
          (maximum, entry) => entry.revenue > maximum ? entry.revenue : maximum,
        );
        if (controller.isLoadingDashboard && analytics == null) {
          return const LoadingPanel();
        }
        return RefreshIndicator(
          onRefresh: controller.loadDashboard,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              Row(
                children: [
                  _DashboardMetric(
                    label: 'Approved revenue',
                    amount: analytics?.totalRevenue ?? 0,
                    color: AppTheme.green,
                    icon: Icons.trending_up,
                    onTap: () =>
                        _showMonthlyBreakdown(controller, pending: false),
                  ),
                  const SizedBox(width: 9),
                  _DashboardMetric(
                    label: 'Pending revenue',
                    amount: pendingRevenue,
                    color: const Color(0xFFF59E0B),
                    icon: Icons.schedule,
                    onTap: () =>
                        _showMonthlyBreakdown(controller, pending: true),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.bar_chart,
                            color: AppTheme.green,
                            size: 19,
                          ),
                          const SizedBox(width: 7),
                          const Expanded(
                            child: Text(
                              'Booking revenue trend',
                              style: TextStyle(
                                color: AppTheme.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            'Tap a bar to select a date',
                            style: TextStyle(
                              color: AppTheme.green,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 128,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final entry in dailyTrend)
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => controller.setDate(entry.date),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: MoneyText(
                                            entry.revenue,
                                            style: const TextStyle(
                                              color: AppTheme.muted,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: 25,
                                          height: dailyMaximum <= 0
                                              ? 10
                                              : (entry.revenue /
                                                        dailyMaximum *
                                                        66)
                                                    .clamp(10.0, 66.0),
                                          decoration: BoxDecoration(
                                            color:
                                                ApiService.formatApiDate(
                                                      entry.date,
                                                    ) ==
                                                    ApiService.formatApiDate(
                                                      controller.selectedDate,
                                                    )
                                                ? AppTheme.green
                                                : const Color(0xFFCBD5D1),
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(6),
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '${entry.date.month}/${entry.date.day}',
                                          style: TextStyle(
                                            color:
                                                ApiService.formatApiDate(
                                                      entry.date,
                                                    ) ==
                                                    ApiService.formatApiDate(
                                                      controller.selectedDate,
                                                    )
                                                ? AppTheme.green
                                                : AppTheme.muted,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Revenue by category · ${formatDate(controller.selectedDate)}',
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF7F0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Daily',
                              style: TextStyle(
                                color: AppTheme.green,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          _RevenueCard(
                            label: 'Food & Drinks',
                            amount: analytics?.categoryRevenue['food'] ?? 0,
                            icon: Icons.ramen_dining,
                            color: const Color(0xFFE4F5EC),
                          ),
                          const SizedBox(width: 7),
                          _RevenueCard(
                            label: 'Fashion',
                            amount: analytics?.categoryRevenue['fashion'] ?? 0,
                            icon: Icons.checkroom,
                            color: const Color(0xFFF4ECFF),
                          ),
                          const SizedBox(width: 7),
                          _RevenueCard(
                            label: 'General Goods',
                            amount: analytics?.categoryRevenue['general'] ?? 0,
                            icon: Icons.headphones,
                            color: const Color(0xFFEAF3FF),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Stall Map',
                              style: TextStyle(
                                color: AppTheme.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            formatDate(controller.selectedDate),
                            style: const TextStyle(
                              color: AppTheme.green,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Availability for the selected date · 30 stalls',
                        style: TextStyle(color: AppTheme.muted, fontSize: 10),
                      ),
                      const SizedBox(height: 9),
                      const Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _MapLegend(
                            color: Color(0xFFD1FAE5),
                            label: 'Available',
                          ),
                          _MapLegend(
                            color: Color(0xFFFFE6A8),
                            label: 'Pending',
                          ),
                          _MapLegend(
                            color: Color(0xFF334155),
                            label: 'Approved',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (controller.stalls.isEmpty)
                        const Text(
                          'No stall data is available for this date.',
                          style: TextStyle(color: AppTheme.muted),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.stalls.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                crossAxisSpacing: 5,
                                mainAxisSpacing: 5,
                                childAspectRatio: 1.2,
                              ),
                          itemBuilder: (context, index) {
                            final stall = controller.stalls[index];
                            final color = switch (stall.status) {
                              'pending' => const Color(0xFFFFE6A8),
                              'approved' => const Color(0xFF334155),
                              _ => const Color(0xFFD1FAE5),
                            };
                            return InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: stall.status == 'approved'
                                  ? () => _showApprovedStallDetails(stall)
                                  : stall.status != 'pending'
                                  ? null
                                  : () {
                                      BookingModel? booking;
                                      for (final item
                                          in controller.pendingBookings) {
                                        if (item.stallId == stall.id &&
                                            ApiService.formatApiDate(
                                                  item.bookingDate,
                                                ) ==
                                                ApiService.formatApiDate(
                                                  controller.selectedDate,
                                                )) {
                                          booking = item;
                                          break;
                                        }
                                      }
                                      if (booking != null) {
                                        _reviewBooking(booking);
                                      }
                                    },
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  stall.id,
                                  style: TextStyle(
                                    color: stall.status == 'approved'
                                        ? Colors.white
                                        : AppTheme.ink,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (controller.errorMessage != null)
                ErrorBanner(
                  controller.errorMessage!,
                  onRetry: controller.loadDashboard,
                ),
              Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Pending Payment Slips',
                              style: TextStyle(
                                color: AppTheme.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF2D4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${controller.pendingBookings.length} pending',
                              style: const TextStyle(
                                color: Color(0xFF966000),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: controller.loadDashboard,
                            icon: const Icon(Icons.refresh, size: 18),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (controller.pendingBookings.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'There are no bookings to review.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.muted),
                        ),
                      )
                    else
                      for (
                        var index = 0;
                        index < controller.pendingBookings.length;
                        index++
                      ) ...[
                        if (index > 0)
                          const Divider(height: 1, indent: 13, endIndent: 13),
                        _PendingRequestRow(
                          booking: controller.pendingBookings[index],
                          onTap: () =>
                              _reviewBooking(controller.pendingBookings[index]),
                        ),
                      ],
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

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(icon, color: Colors.white70, size: 17),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: MoneyText(
                    amount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap for monthly summary ›',
                  style: TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 9)),
      ],
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppTheme.muted),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: MoneyText(
                  amount,
                  style: const TextStyle(
                    color: AppTheme.green,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingInfoRow extends StatelessWidget {
  const _BookingInfoRow({
    required this.label,
    required this.value,
    this.valueColor = AppTheme.ink,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.muted, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingRequestRow extends StatelessWidget {
  const _PendingRequestRow({required this.booking, required this.onTap});

  final BookingModel booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Stall ${booking.stallId}',
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF7F0),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          ApiService.formatApiDate(booking.bookingDate),
                          style: const TextStyle(
                            color: AppTheme.deepGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Shop: ${booking.shopName ?? 'Unavailable'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.muted, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppTheme.muted, size: 20),
          ],
        ),
      ),
    );
  }
}
