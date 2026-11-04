import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/admin_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_card.dart';
import '../../widgets/page_header.dart';

enum _Period { daily, monthly }

class _Point {
  const _Point(this.chartLabel, this.rowLabel, this.value, this.count);
  final String chartLabel;
  final String rowLabel;
  final double value;
  final int count;
}

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key});

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  _Period _period = _Period.daily;

  List<_Point> _points() {
    final now = DateTime.now();
    final today = dateOnly(now);
    final result = <_Point>[];
    if (_period == _Period.daily) {
      for (var i = 13; i >= 0; i--) {
        final day = today.subtract(Duration(days: i));
        final list = adminStore.approvedOnDay(day);
        result.add(_Point(DateFormat('d').format(day),
            DateFormat('EEE d MMM').format(day), adminStore.sum(list), list.length));
      }
    } else {
      for (var i = 5; i >= 0; i--) {
        final m = DateTime(now.year, now.month - i, 1);
        final list = adminStore.approvedInMonth(m.year, m.month);
        result.add(_Point(DateFormat('MMM').format(m),
            DateFormat('MMMM yyyy').format(m), adminStore.sum(list), list.length));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: adminStore,
      builder: (context, _) {
        final points = _points();
        final rows = points.reversed.toList(); // latest first
        final total = points.fold<double>(0, (a, p) => a + p.value);
        final bookingCount = points.fold<int>(0, (a, p) => a + p.count);
        final periodName =
            _period == _Period.daily ? 'last 14 days' : 'last 6 months';

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const PageHeader(
              eyebrow: 'Revenue',
              title: 'Market income.',
              subtitle: 'Daily and monthly summary of approved bookings.',
            ),
            const SizedBox(height: 16),
            SegmentedButton<_Period>(
              segments: const [
                ButtonSegment(value: _Period.daily, label: Text('Daily')),
                ButtonSegment(value: _Period.monthly, label: Text('Monthly')),
              ],
              selected: {_period},
              onSelectionChanged: (s) => setState(() => _period = s.first),
            ),
            const SizedBox(height: 16),
            AppCard(
              color: AppColors.green,
              bordered: false,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total revenue, $periodName',
                      style: text.bodyMedium
                          ?.copyWith(color: AppColors.onGreenMuted)),
                  const SizedBox(height: 4),
                  Text(baht(total),
                      style: text.headlineMedium?.copyWith(
                          color: AppColors.cream, fontWeight: FontWeight.w800)),
                  Text('$bookingCount approved bookings',
                      style: text.bodySmall
                          ?.copyWith(color: AppColors.onGreenMuted)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 10),
              child: _BarChart(points: points),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: AppColors.border),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rows[i].rowLabel,
                                    style: text.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600)),
                                Text('${rows[i].count} bookings',
                                    style: text.bodySmall
                                        ?.copyWith(color: AppColors.muted)),
                              ],
                            ),
                          ),
                          Text(baht(rows[i].value),
                              style: text.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.points});
  final List<_Point> points;

  @override
  Widget build(BuildContext context) {
    final maxValue =
        points.fold<double>(0, (a, p) => p.value > a ? p.value : a);
    const maxBar = 130.0;
    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final p in points)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Tooltip(
                      message: '${p.rowLabel}: ${baht(p.value)}',
                      child: Container(
                        height: maxValue == 0 ? 0 : p.value / maxValue * maxBar,
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(p.chartLabel,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.muted)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
