import 'package:flutter/material.dart';
import 'package:mfu_market/controller/stall_controller.dart';
import 'package:mfu_market/model/market_event.dart';
import 'package:mfu_market/model/stall_model.dart';
import 'package:mfu_market/model/user_model.dart';
import 'package:mfu_market/theme.dart';
import 'package:mfu_market/utils.dart';
import 'package:mfu_market/views/review_booking_view.dart';
import 'package:mfu_market/views/widgets.dart';

class StallPickerView extends StatefulWidget {
  final UserModel user;
  final MarketEvent event;

  const StallPickerView({super.key, required this.user, required this.event});

  @override
  State<StallPickerView> createState() => _StallPickerViewState();
}

class _StallPickerViewState extends State<StallPickerView> {
  final stallController = StallController();
  final filters = const ['All stalls', 'With power', 'Covered'];

  List<StallModel> stalls = [];
  Set<int> freeIds = {};
  StallModel? selected;
  String filter = 'All stalls';
  bool loading = true;

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
      stalls = active;
      freeIds = free.map((s) => s.id).toSet();
      selected = free.isEmpty ? null : free.first;
      loading = false;
    });
  }

  List<StallModel> get visible {
    return stalls.where((s) {
      if (filter == 'With power') return s.power;
      if (filter == 'Covered') return s.covered;
      return true;
    }).toList();
  }

  void setFilter(String value) {
    setState(() {
      filter = value;
      final list = visible;
      final current = selected;
      if (current == null || !list.any((s) => s.id == current.id)) {
        final firstFree = list.where((s) => freeIds.contains(s.id));
        selected = firstFree.isEmpty ? null : firstFree.first;
      }
    });
  }

  Future<void> next() async {
    final stall = selected;
    if (stall == null) return;
    final booked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewBookingView(
            user: widget.user, event: widget.event, stall: stall),
      ),
    );
    if (!mounted) return;
    if (booked == true) {
      Navigator.pop(context, true);
    } else {
      load();
    }
  }

  Widget buildCell(StallModel s) {
    final isFree = freeIds.contains(s.id);
    final isSelected = selected?.id == s.id;
    Color bg = AppColors.neutralBg;
    Color fg = const Color(0xFF9AA09A);
    Color line = AppColors.neutralBg;
    if (isFree) {
      bg = AppColors.primaryTint;
      fg = AppColors.primary;
      line = AppColors.primary;
    }
    if (isSelected) {
      bg = AppColors.primary;
      fg = Colors.white;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: isFree ? () => setState(() => selected = s) : null,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: line),
        ),
        child: Text(
          s.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: fg,
            decoration: isFree ? null : TextDecoration.lineThrough,
          ),
        ),
      ),
    );
  }

  Widget legend(Color fill, Color line, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: line),
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  Widget infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget buildSelectedCard(StallModel s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Stall ${s.label}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
              const Text('Selected',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(s.note,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              infoChip(Icons.straighten, s.sizeLabel),
              if (s.covered) infoChip(Icons.roofing_outlined, 'Covered'),
              if (s.power) infoChip(Icons.bolt, 'Power'),
              infoChip(Icons.restaurant_outlined, s.productType),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = visible;
    final availableCount = list.where((s) => freeIds.contains(s.id)).length;
    final bookedCount = list.length - availableCount;
    final sel = selected;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Choose your stall'),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      children: [
                        const StepHeader(step: '01 / 03'),
                        const SizedBox(height: 8),
                        const Text('A space for your business.',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                            '${widget.event.name} · ${formatFullDate(widget.event.date)}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMuted)),
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
                                    onTap: () => setFilter(f),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Pick your spot',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                  '$availableCount available, $bookedCount booked',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              if (list.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('No stalls match this filter.',
                                      style: TextStyle(
                                          color: AppColors.textMuted)),
                                )
                              else
                                GridView.count(
                                  crossAxisCount: 5,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 1.3,
                                  children: [for (final s in list) buildCell(s)],
                                ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.neutralBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text('ENTRANCE',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                          color: AppColors.textMuted)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            legend(AppColors.primaryTint, AppColors.primary,
                                'Available'),
                            const SizedBox(width: 16),
                            legend(AppColors.neutralBg, AppColors.neutralBg,
                                'Booked'),
                            const SizedBox(width: 16),
                            legend(AppColors.primary, AppColors.primary,
                                'Selected'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (sel != null) buildSelectedCard(sel),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        child: Row(
          children: [
            PriceTag(
              price: sel == null ? '—' : baht(sel.pricePerDay),
              caption: 'Excl. fees & VAT',
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                style: primaryButtonStyle(),
                onPressed: sel == null ? null : next,
                child: Text(
                    sel == null ? 'Choose a stall' : 'Continue with ${sel.label}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
