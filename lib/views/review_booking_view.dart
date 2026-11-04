import 'package:flutter/material.dart';
import 'package:mfu_market/controller/booking_controller.dart';
import 'package:mfu_market/model/market_event.dart';
import 'package:mfu_market/model/stall_model.dart';
import 'package:mfu_market/model/user_model.dart';
import 'package:mfu_market/theme.dart';
import 'package:mfu_market/utils.dart';
import 'package:mfu_market/views/booking_confirmed_view.dart';
import 'package:mfu_market/views/widgets.dart';

class ReviewBookingView extends StatefulWidget {
  final UserModel user;
  final MarketEvent event;
  final StallModel stall;

  const ReviewBookingView({
    super.key,
    required this.user,
    required this.event,
    required this.stall,
  });

  @override
  State<ReviewBookingView> createState() => _ReviewBookingViewState();
}

class _ReviewBookingViewState extends State<ReviewBookingView> {
  final bookingController = BookingController();
  final businessController = TextEditingController();
  final contactController = TextEditingController();
  final emailController = TextEditingController();
  bool agreed = false;
  bool submitting = false;
  String? errorMessage;

  @override
  void dispose() {
    businessController.dispose();
    contactController.dispose();
    emailController.dispose();
    super.dispose();
  }

  String? validate() {
    if (businessController.text.trim().isEmpty) {
      return 'Please enter your business name.';
    }
    if (contactController.text.trim().isEmpty) {
      return 'Please enter a contact name.';
    }
    final email = emailController.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  Future<void> submit() async {
    final problem = validate();
    if (problem != null) {
      setState(() => errorMessage = problem);
      return;
    }
    setState(() {
      submitting = true;
      errorMessage = null;
    });
    try {
      final booking = await bookingController.requestBooking(
        widget.user.id,
        widget.stall,
        widget.event.date,
        businessName: businessController.text.trim(),
        contactName: contactController.text.trim(),
        email: emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() => submitting = false);
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmedView(
              booking: booking, event: widget.event, stall: widget.stall),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = cleanError(e);
        submitting = false;
      });
    }
  }

  Widget fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 12),
        child: Text(text,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      );

  Widget line(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: strong ? 14 : 13,
                  fontWeight: strong ? FontWeight.w800 : FontWeight.normal,
                  color: strong ? AppColors.text : AppColors.textMuted)),
          Text(value,
              style: TextStyle(
                  fontSize: strong ? 20 : 13,
                  fontWeight: strong ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final s = widget.stall;
    final total = totalFor(s.pricePerDay);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Review & book'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  const StepHeader(step: '02 / 03'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const MarketImage(height: 48, width: 56, radius: 10),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text('${formatDay(e.date)} · ${e.venue}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Stall ${s.label} · ${s.sizeLabel}',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                        Text(
                            [
                              if (s.covered) 'Covered',
                              if (s.power) 'Power',
                            ].join(' · '),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('Your business',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  fieldLabel('Business name'),
                  TextField(controller: businessController),
                  fieldLabel('Contact name'),
                  TextField(controller: contactController),
                  fieldLabel('Email address'),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 22),
                  const Text('The numbers',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  line('Stall ${s.label} · 1 day', money(s.pricePerDay)),
                  line('Booking fee', money(bookingFee)),
                  line('VAT (${(vatRate * 100).round()}%)',
                      money(vatFor(s.pricePerDay))),
                  const Divider(height: 20, color: AppColors.border),
                  line('Total to pay', money(total), strong: true),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.payments_outlined,
                            size: 20, color: AppColors.primary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pay at the market',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                              Text('Settled with the organiser on the day',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: agreed,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => agreed = v ?? false),
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                              'I agree to the market rules and cancellation '
                              'policy. Free cancellation until the sales date.',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textMuted)),
                        ),
                      ),
                    ],
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(errorMessage!,
                        style: const TextStyle(color: AppColors.danger)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        child: ElevatedButton(
          style: primaryButtonStyle(),
          onPressed: (agreed && !submitting) ? submit : null,
          child: submitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Text('Book stall · ${money(total)}'),
        ),
      ),
    );
  }
}
