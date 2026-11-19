import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/booking_controller.dart';
import '../../models/stall_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'payment_upload_screen.dart';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BookingController>().load();
    });
  }

  static const _categories = [
    _CategoryInfo(
      id: 'food',
      label: 'Food & Drinks',
      description: 'Fresh food, meals, and snacks',
      emoji: '🍲',
      tint: Color(0xFFFFF0E4),
    ),
    _CategoryInfo(
      id: 'fashion',
      label: 'Fashion',
      description: 'Clothing, shoes, and bags',
      emoji: '👚',
      tint: Color(0xFFF4ECFF),
    ),
    _CategoryInfo(
      id: 'general',
      label: 'General Goods',
      description: 'Household items, accessories, and lifestyle products',
      emoji: '🧻',
      tint: Color(0xFFEAF3FF),
    ),
  ];

  Future<void> _openBooking(StallModel stall) async {
    await showDialog<void>(
      context: context,
      builder: (_) => PaymentUploadScreen(stall: stall),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingController>(
      builder: (context, controller, _) {
        final matches = _categories
            .where((category) => category.id == controller.selectedCategory)
            .toList(growable: false);
        if (matches.isEmpty) {
          return _categoryPicker(controller);
        }
        final selected = matches.first;

        final stalls = controller.stalls;
        return RefreshIndicator(
          onRefresh: controller.loadStalls,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF7F0),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          selected.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected category',
                              style: TextStyle(
                                color: AppTheme.muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              selected.label,
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => controller.selectCategory(null),
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBE9D9)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Stalls for ${ApiService.formatApiDate(controller.selectedDate)}',
                        style: const TextStyle(
                          color: AppTheme.deepGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        DateUtils.isSameDay(
                              controller.selectedDate,
                              DateTime.now(),
                            )
                            ? 'TODAY'
                            : 'ADVANCE BOOKING',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const SectionTitle(
                'Choose a Stall',
                subtitle: 'Green stalls are available to book.',
              ),
              const SizedBox(height: 16),
              const _StallLegend(),
              const SizedBox(height: 12),
              if (controller.errorMessage != null)
                ErrorBanner(
                  controller.errorMessage!,
                  onRetry: controller.loadStalls,
                ),
              if (controller.isLoadingStalls && stalls.isEmpty)
                const SizedBox(height: 220, child: LoadingPanel())
              else if (stalls.isEmpty)
                const _EmptyPanel(
                  icon: Icons.store_mall_directory_outlined,
                  message: 'No stalls are available for this date.',
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stalls.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 7,
                    mainAxisSpacing: 7,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (context, index) {
                    final stall = stalls[index];
                    return _StallTile(
                      stall: stall,
                      isCategoryMatch: stall.category == selected.id,
                      onTap: () => _openBooking(stall),
                    );
                  },
                ),
              const SizedBox(height: 14),
              Text(
                'Showing ${stalls.length} stalls · ${selected.label}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.muted, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _categoryPicker(BookingController controller) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
      children: [
        const SectionTitle(
          'Choose a Category',
          subtitle: 'Select a market zone to view daily stall availability.',
        ),
        const SizedBox(height: 16),
        for (final category in _categories) ...[
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => controller.selectCategory(category.id),
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: category.tint,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        category.emoji,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.label,
                            style: const TextStyle(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.description,
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppTheme.muted),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 11),
        ],
        if (controller.isLoadingStalls)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(),
          ),
        if (controller.errorMessage != null) ...[
          const SizedBox(height: 10),
          ErrorBanner(controller.errorMessage!, onRetry: controller.load),
        ],
      ],
    );
  }
}

class _CategoryInfo {
  const _CategoryInfo({
    required this.id,
    required this.label,
    required this.description,
    required this.emoji,
    required this.tint,
  });

  final String id;
  final String label;
  final String description;
  final String emoji;
  final Color tint;
}

class _StallTile extends StatelessWidget {
  const _StallTile({
    required this.stall,
    required this.isCategoryMatch,
    required this.onTap,
  });

  final StallModel stall;
  final bool isCategoryMatch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = stall.isAvailable && isCategoryMatch;
    final color = switch (stall.status) {
      'pending' => const Color(0xFFFFF0CE),
      'approved' => const Color(0xFFE5EAE8),
      _ => available ? AppTheme.green : const Color(0xFFF0F3F1),
    };
    final foreground = switch (stall.status) {
      'pending' => const Color(0xFF925E00),
      'approved' => const Color(0xFF64726D),
      _ => available ? Colors.white : const Color(0xFFADB8B3),
    };
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: available ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: available
                  ? AppTheme.deepGreen
                  : foreground.withValues(alpha: 0.3),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stall.id,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                stall.status == 'pending'
                    ? 'Pending'
                    : stall.status == 'approved'
                    ? 'Booked'
                    : '฿${stall.price.toStringAsFixed(0)}',
                maxLines: 1,
                style: TextStyle(color: foreground, fontSize: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StallLegend extends StatelessWidget {
  const _StallLegend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 13,
      runSpacing: 8,
      children: [
        _LegendDot(color: AppTheme.green, label: 'Available'),
        _LegendDot(color: Color(0xFFFFD779), label: 'Pending'),
        _LegendDot(color: Color(0xFFBFCAC5), label: 'Booked'),
        _LegendDot(color: Color(0xFFE8EEEB), label: 'Other category'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.muted),
        ),
      ],
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      children: [
        Icon(icon, color: AppTheme.muted, size: 38),
        const SizedBox(height: 10),
        Text(message, style: const TextStyle(color: AppTheme.muted)),
      ],
    ),
  );
}
