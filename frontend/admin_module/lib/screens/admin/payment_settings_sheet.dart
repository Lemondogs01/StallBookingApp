import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/admin_store.dart';

/// Edit the PromptPay account that vendors pay into.
Future<void> showPaymentSettings(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _PaymentSettingsForm(),
  );
}

class _PaymentSettingsForm extends StatefulWidget {
  const _PaymentSettingsForm();

  @override
  State<_PaymentSettingsForm> createState() => _PaymentSettingsFormState();
}

class _PaymentSettingsFormState extends State<_PaymentSettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _id;
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _id = TextEditingController(text: adminStore.promptPayId);
    _name = TextEditingController(text: adminStore.accountName);
  }

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    adminStore.updatePaymentSettings(
      promptPayId: _id.text.trim(),
      accountName: _name.text.trim(),
    );
    Navigator.pop(context);
    messenger.showSnackBar(
        const SnackBar(content: Text('Payment account updated')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Receiving account',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Vendors scan this PromptPay account to pay for a stall.',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              TextFormField(
                controller: _id,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 13,
                decoration: const InputDecoration(
                  labelText: 'PromptPay ID',
                  helperText: 'Phone number (10 digits) or national ID (13 digits)',
                  counterText: '',
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.length != 10 && value.length != 13) {
                    return 'Enter 10 digits (phone) or 13 digits (ID)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Account name'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter the account name'
                    : null,
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
