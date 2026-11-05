import 'package:flutter/material.dart';
import 'package:mfu_market/controller/stall_controller.dart';
import 'package:mfu_market/model/market_event.dart';
import 'package:mfu_market/model/user_model.dart';
import 'package:mfu_market/theme.dart';
import 'package:mfu_market/utils.dart';
import 'package:mfu_market/views/pill.dart';
import 'package:mfu_market/views/stall_picker_view.dart';
import 'package:mfu_market/views/widgets.dart';

class EventDetailView extends StatefulWidget {
  final UserModel user;
  final MarketEvent event;

  const EventDetailView({super.key, required this.user, required this.event});

  @override
  State<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<EventDetailView> {
  final stallController = StallController();
  int? left;
  int total = 0;
  double fromPrice = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final active = await stallController.fetchActiveStalls();
    final free = await stallController.fetchFreeStalls(date: widget.event.date);
    if (!mounted) return;
    setState(() {
      total = active.length;
      left = free.length;
      fromPrice = active.isEmpty
          ? 0
          : active.map((s) => s.pricePerDay).reduce((a, b) => a < b ? a : b);
    });
  }

  Future<void> chooseStall() async {
    final booked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StallPickerView(user: widget.user, event: widget.event),
      ),
    );
    if (!mounted) return;
    if (booked == true) {
      Navigator.pop(context, true);
    } else {
      load();
    }
  }

  Widget infoRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget statBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget feature(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final n = left;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'The market'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  MarketImage(
                    height: 170,
                    radius: 18,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('1 / 4',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: SectionLabel(e.tagline)),
                      if (n != null)
                        Pill(
                          label: n == 1 ? '1 stall left' : '$n stalls left',
                          background: AppColors.successBg,
                          foreground: AppColors.success,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(e.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  infoRow(Icons.calendar_today_outlined,
                      formatLongDate(e.date), e.hours),
                  infoRow(Icons.location_on_outlined, e.venue, e.area),
                  const SizedBox(height: 8),
                  const Text('Made for independent makers',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(e.about,
                      style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      statBox(e.visitors, 'expected visitors'),
                      const SizedBox(width: 12),
                      statBox('$total', 'stalls in total'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      feature(Icons.roofing_outlined, 'Covered stalls'),
                      feature(Icons.bolt, 'Power included'),
                      feature(Icons.verified_outlined, 'Verified host'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        child: Row(
          children: [
            PriceTag(price: baht(fromPrice), caption: 'Excl. fees & VAT'),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                style: primaryButtonStyle(),
                onPressed: chooseStall,
                child: const Text('Choose a stall'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
