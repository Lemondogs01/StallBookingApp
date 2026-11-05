import 'package:flutter/material.dart';
import 'package:mfu_market/controller/stall_controller.dart';
import 'package:mfu_market/model/market_event.dart';
import 'package:mfu_market/model/user_model.dart';
import 'package:mfu_market/theme.dart';
import 'package:mfu_market/utils.dart';
import 'package:mfu_market/views/event_detail_view.dart';
import 'package:mfu_market/views/pill.dart';
import 'package:mfu_market/views/widgets.dart';

class DiscoverView extends StatefulWidget {
  final UserModel user;
  final VoidCallback onBooked;

  const DiscoverView({super.key, required this.user, required this.onBooked});

  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> {
  final stallController = StallController();
  final events = buildMarketEvents();
  final filters = const ['All events', 'Craft & design', 'Food'];

  String filter = 'All events';
  String query = '';
  late Future<Map<int, int>> leftFuture;

  @override
  void initState() {
    super.initState();
    loadLeft();
  }

  void loadLeft() {
    leftFuture = countLeft();
  }

  Future<Map<int, int>> countLeft() async {
    final result = <int, int>{};
    for (final e in events) {
      final free = await stallController.fetchFreeStalls(date: e.date);
      result[e.id] = free.length;
    }
    return result;
  }

  List<MarketEvent> get visibleEvents {
    final q = query.trim().toLowerCase();
    return events
        .where((e) =>
            (filter == 'All events' || e.categories.contains(filter)) &&
            (q.isEmpty || e.name.toLowerCase().contains(q)))
        .toList();
  }

  Future<void> openEvent(MarketEvent event) async {
    final booked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailView(user: widget.user, event: event),
      ),
    );
    if (!mounted) return;
    setState(loadLeft);
    if (booked == true) widget.onBooked();
  }

  String leftLabel(int? n) {
    if (n == null) return '…';
    return n == 1 ? '1 stall left' : '$n stalls left';
  }

  Widget buildHeader() {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
              color: AppColors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.storefront_outlined,
              size: 16, color: Colors.white),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text('MFUgrowtogether',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Chiang rai', style: TextStyle(fontSize: 12)),
              Icon(Icons.keyboard_arrow_down, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildFeaturedCard(MarketEvent e, int? left) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => openEvent(e),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MarketImage(
                height: 150,
                radius: 16,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(formatBadgeDate(e.date),
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                      const Spacer(),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.bookmark_border, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 12, 6, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.verified_outlined,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('${e.venue}, ${e.area.split(', ').last}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Pill(
                          label: leftLabel(left),
                          background: AppColors.successBg,
                          foreground: AppColors.success,
                        ),
                        const Spacer(),
                        const Text.rich(TextSpan(
                          text: 'From ',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                          children: [
                            TextSpan(
                              text: '฿100',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text),
                            ),
                            TextSpan(text: ' / day'),
                          ],
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCompactCard(MarketEvent e, int? left) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 12),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => openEvent(e),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const MarketImage(height: 56, width: 64, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text('${formatDay(e.date)} · ${leftLabel(left)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildEventList() {
    return FutureBuilder<Map<int, int>>(
      future: leftFuture,
      builder: (context, snapshot) {
        final left = snapshot.data;
        final list = visibleEvents;
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Column(
              children: [
                Text('No markets found',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('Try another search or category.',
                    style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildFeaturedCard(list.first, left?[list.first.id]),
            for (final e in list.skip(1)) buildCompactCard(e, left?[e.id]),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        buildHeader(),
        const SizedBox(height: 22),
        const Text('Small business.\nBig possibilities.',
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w800, height: 1.15)),
        const SizedBox(height: 8),
        const Text('Find your people. Book your next market.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(height: 18),
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: InputDecoration(
            hintText: 'Search markets & events',
            hintStyle:
                const TextStyle(fontSize: 14, color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search, size: 20),
            fillColor: AppColors.primaryTint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in filters)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoicePill(
                    label: f,
                    selected: filter == f,
                    onTap: () => setState(() => filter = f),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text('Your next selling spot',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() {
                filter = 'All events';
                query = '';
              }),
              child: const Text('View all',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        buildEventList(),
      ],
    );
  }
}
