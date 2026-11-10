import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../models/payment.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_card.dart';
import '../../widgets/page_header.dart';
import '../../widgets/payment_review_sheet.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_chip.dart';
import 'payment_settings_sheet.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  PaymentStatus? _filter; // null = all

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: adminStore,
      builder: (context, _) {
        final all = adminStore.payments;
        final items =
            _filter == null ? all : all.where((p) => p.status == _filter).toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: items.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) return _header(context, all.length, items.isEmpty);
            final payment = items[i - 1];
            final booking = adminStore.bookingById(payment.bookingId);
            if (booking == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => showPaymentReview(context, booking),
                child: AppCard(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.greenSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(booking.stallCode,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.green)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(booking.userName,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            Text(
                                '${bookingCode(booking.id)}  ·  ${fmtDate(booking.bookingDate)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.muted)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(baht(payment.amount),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          PaymentStatusChip(payment.status),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _header(BuildContext context, int totalCount, bool empty) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          eyebrow: 'Payments',
          title: 'Payment history.',
          subtitle: 'Check slips and track every payment.',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Collected',
                value: baht(adminStore.collectedTotal),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                icon: Icons.hourglass_top,
                label: 'Awaiting check',
                value: baht(adminStore.pendingTotal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                    color: AppColors.greenSoft, shape: BoxShape.circle),
                child: const Icon(Icons.qr_code_2, color: AppColors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Receiving account',
                        style: text.bodySmall?.copyWith(color: AppColors.muted)),
                    Text('PromptPay ${formatPromptPayId(adminStore.promptPayId)}',
                        style: text.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(adminStore.accountName, style: text.bodySmall),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => showPaymentSettings(context),
                child: const Text('Edit'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('All ($totalCount)'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
              ),
              for (final s in PaymentStatus.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${s.label} (${adminStore.countPayments(s)})'),
                    selected: _filter == s,
                    onSelected: (_) => setState(() => _filter = s),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (empty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('No payments in this status')),
          ),
      ],
    );
  }
}
