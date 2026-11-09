import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../controllers/booking_controller.dart';
import '../../controllers/payment_controller.dart';
import '../../models/booking_model.dart';
import '../../models/stall_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class PaymentUploadScreen extends StatefulWidget {
  const PaymentUploadScreen({
    super.key,
    required this.stall,
    this.existingBooking,
  });

  final StallModel stall;
  final BookingModel? existingBooking;

  @override
  State<PaymentUploadScreen> createState() => _PaymentUploadScreenState();
}

class _PaymentUploadScreenState extends State<PaymentUploadScreen> {
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  String? _filename;
  BookingModel? _booking;
  bool _isCreatingBooking = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _booking = widget.existingBooking;
  }

  Future<void> _pickImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 5 * 1024 * 1024) {
        setState(
          () => _localError = 'The payment slip must be 5 MB or smaller.',
        );
        return;
      }
      setState(() {
        _filename = file.name;
        _imageBytes = bytes;
        _localError = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _localError =
              'Could not open that image. Please choose another one.',
        );
      }
    }
  }

  Future<void> _submit() async {
    final bytes = _imageBytes;
    final bookingController = context.read<BookingController>();
    final paymentController = context.read<PaymentController>();
    final replacingSlip = _booking?.slipUrl?.isNotEmpty == true;
    if (bytes == null) {
      setState(() => _localError = 'Choose a payment slip before continuing.');
      return;
    }

    setState(() {
      _localError = null;
      _isCreatingBooking = _booking == null;
    });
    try {
      if (replacingSlip) {
        if (_booking?.id == null) {
          throw const FormatException('The booking record could not be found.');
        }
        await paymentController.replaceSlip(
          bookingId: _booking!.id!,
          imageBytes: bytes,
          filename: _filename ?? 'payment-slip.jpg',
        );
      } else {
        _booking ??= await bookingController.createBooking(widget.stall);
      }
      if (_booking?.id == null) {
        throw const FormatException('The booking record could not be found.');
      }
      if (!replacingSlip) {
        await paymentController.submitSlip(
          bookingId: _booking!.id!,
          amount: _booking!.price,
          imageBytes: bytes,
          filename: _filename ?? 'payment-slip.jpg',
        );
      }
      if (!mounted) return;
      await bookingController.load();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _localError = _booking == null
              ? bookingController.errorMessage ??
                    'Could not create the booking.'
              : paymentController.errorMessage ??
                    (replacingSlip
                        ? 'Could not replace the slip. You can try again.'
                        : 'Could not submit the slip. You can try again.');
        });
      }
    } finally {
      if (mounted) setState(() => _isCreatingBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingController = context.watch<BookingController>();
    final paymentController = context.watch<PaymentController>();
    final api = context.read<ApiService>();
    final busy = _isCreatingBooking || paymentController.isSubmitting;
    final isReplacingSlip = _booking?.slipUrl?.isNotEmpty == true;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            15,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isReplacingSlip
                          ? 'Edit Payment Slip'
                          : _booking == null
                          ? 'Pay for Your Stall'
                          : 'Submit Payment Slip',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                '${widget.stall.id} · ${formatDate(_booking?.bookingDate ?? bookingController.selectedDate)}',
                style: const TextStyle(
                  color: AppTheme.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8F6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Amount Due',
                      style: TextStyle(color: AppTheme.muted),
                    ),
                    const SizedBox(height: 4),
                    MoneyText(
                      _booking?.price ?? widget.stall.price,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD7E9E0)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      size: 112,
                      color: AppTheme.deepGreen,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Pay with PromptPay and upload your slip',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Contact the market administrator for the payment QR code.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: busy ? null : _pickImage,
                icon: Icon(
                  _imageBytes == null ? Icons.upload_file : Icons.check_circle,
                ),
                label: Text(
                  _imageBytes == null
                      ? isReplacingSlip
                            ? 'Choose Replacement Slip'
                            : 'Choose Payment Slip'
                      : 'Choose Another Image',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              if (_imageBytes != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    _imageBytes!,
                    height: 210,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(
                      height: 80,
                      child: Center(
                        child: Text('Image preview is unavailable.'),
                      ),
                    ),
                  ),
                ),
                if (_filename != null)
                  Text(
                    _filename!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.muted, fontSize: 11),
                  ),
              ],
              if (_imageBytes == null && isReplacingSlip) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    api.resolveMediaUrl(_booking!.slipUrl!),
                    height: 210,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(
                      height: 80,
                      child: Center(
                        child: Text('Current slip preview is unavailable.'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Current payment slip',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.muted, fontSize: 11),
                ),
              ],
              if (_localError != null) ...[
                const SizedBox(height: 12),
                ErrorBanner(_localError!),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: busy ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppTheme.green,
                ),
                child: busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isReplacingSlip
                            ? 'Replace Payment Slip'
                            : _booking == null
                            ? 'Book Stall and Submit Slip'
                            : 'Submit Payment Slip',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
