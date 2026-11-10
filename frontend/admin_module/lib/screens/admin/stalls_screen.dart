import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../models/stall.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_card.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/page_header.dart';
import '../../widgets/status_chip.dart';
import 'stall_form.dart';

class StallsScreen extends StatefulWidget {
  const StallsScreen({super.key});

  @override
  State<StallsScreen> createState() => _StallsScreenState();
}

class _StallsScreenState extends State<StallsScreen> {
  String _query = '';
  String? _zone; // null = all zones

  Future<void> _delete(Stall s) async {
    final ok = await confirmAction(
      context,
      title: 'Delete stall ${s.code}?',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!ok || !mounted) return;
    final deleted = adminStore.deleteStall(s.id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(deleted
          ? 'Stall ${s.code} deleted'
          : 'Cannot delete ${s.code}: it has upcoming bookings'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showStallForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add stall'),
      ),
      body: ListenableBuilder(
        listenable: adminStore,
        builder: (context, _) {
          final q = _query.trim().toLowerCase();
          final items = adminStore.stalls.where((s) {
            final matchZone = _zone == null || s.zone == _zone;
            final matchQuery = q.isEmpty ||
                s.code.toLowerCase().contains(q) ||
                s.productType.toLowerCase().contains(q);
            return matchZone && matchQuery;
          }).toList();

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: PageHeader(
                    eyebrow: 'Stalls',
                    title: 'Your stalls.',
                    subtitle: 'Add, edit and manage every selling spot.',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by code or product type',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('All zones'),
                        selected: _zone == null,
                        onSelected: (_) => setState(() => _zone = null),
                      ),
                    ),
                    for (final z in AdminStore.zones)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('Zone $z'),
                          selected: _zone == z,
                          onSelected: (_) => setState(() => _zone = z),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('No stalls match your filters'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _StallCard(
                          stall: items[i],
                          onEdit: () => showStallForm(context, stall: items[i]),
                          onDelete: () => _delete(items[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StallCard extends StatelessWidget {
  const _StallCard({
    required this.stall,
    required this.onEdit,
    required this.onDelete,
  });

  final Stall stall;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.greenSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(stall.code,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.green)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Zone ${stall.zone}  ·  ${stall.size}',
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text(
                    '${stall.productType}  ·  ${baht(stall.pricePerDay)} / day',
                    style: text.bodySmall?.copyWith(color: AppColors.muted)),
                const SizedBox(height: 6),
                StallStatusChip(stall.status),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}
