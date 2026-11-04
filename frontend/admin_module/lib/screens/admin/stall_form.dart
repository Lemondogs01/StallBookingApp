import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../models/stall.dart';

/// Bottom sheet used for both "Add stall" and "Edit stall".
Future<void> showStallForm(BuildContext context, {Stall? stall}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _StallForm(stall: stall),
  );
}

class _StallForm extends StatefulWidget {
  const _StallForm({this.stall});
  final Stall? stall;

  @override
  State<_StallForm> createState() => _StallFormState();
}

class _StallFormState extends State<_StallForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _size;
  late final TextEditingController _price;
  late String _zone;
  late String _productType;
  late StallStatus _status;

  bool get _isEdit => widget.stall != null;

  @override
  void initState() {
    super.initState();
    final s = widget.stall;
    _code = TextEditingController(text: s?.code ?? '');
    _size = TextEditingController(text: s?.size ?? '');
    _price = TextEditingController(
        text: s == null ? '' : s.pricePerDay.toStringAsFixed(0));
    _zone = s?.zone ?? AdminStore.zones.first;
    _productType = s?.productType ?? AdminStore.productTypes.first;
    _status = s?.status ?? StallStatus.available;
  }

  @override
  void dispose() {
    _code.dispose();
    _size.dispose();
    _price.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final draft = Stall(
      id: widget.stall?.id ?? 0,
      code: _code.text.trim().toUpperCase(),
      zone: _zone,
      size: _size.text.trim(),
      pricePerDay: double.parse(_price.text.trim()),
      productType: _productType,
      status: _status,
    );
    if (_isEdit) {
      adminStore.updateStall(draft);
    } else {
      adminStore.addStall(draft);
    }
    Navigator.pop(context);
    messenger.showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Stall updated' : 'Stall added')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_isEdit ? 'Edit stall' : 'Add stall',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Stall code'),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Enter a stall code';
                  if (adminStore.codeExists(value,
                      excludeId: widget.stall?.id)) {
                    return 'This code is already used';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _zone,
                decoration: const InputDecoration(labelText: 'Zone'),
                items: [
                  for (final z in AdminStore.zones)
                    DropdownMenuItem(value: z, child: Text('Zone $z')),
                ],
                onChanged: (v) => setState(() => _zone = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _size,
                decoration: const InputDecoration(
                    labelText: 'Size', hintText: 'e.g. 3x3 m'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter the stall size' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Price per day', prefixText: '฿ '),
                validator: (v) {
                  final n = double.tryParse(v?.trim() ?? '');
                  if (n == null) return 'Enter a number';
                  if (n <= 0) return 'Price must be more than 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _productType,
                decoration: const InputDecoration(labelText: 'Product type'),
                items: [
                  for (final t in AdminStore.productTypes)
                    DropdownMenuItem(value: t, child: Text(t)),
                ],
                onChanged: (v) => setState(() => _productType = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<StallStatus>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  for (final s in StallStatus.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                child: Text(_isEdit ? 'Save changes' : 'Add stall'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
