import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../auth/change_password_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();
  final _shopController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _requestedLoad = false;
  bool _editing = false;
  Uint8List? _imageBytes;
  String? _imageFilename;
  String? _pickerError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requestedLoad) {
      _requestedLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<ProfileController>().load();
      });
    }
  }

  @override
  void dispose() {
    _shopController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _startEditing(UserModel profile) {
    _shopController.text = profile.shopName;
    _nameController.text = profile.realName;
    _phoneController.text = profile.phone;
    setState(() {
      _editing = true;
      _imageBytes = null;
      _imageFilename = null;
      _pickerError = null;
    });
  }

  Future<void> _pickProfileImage() async {
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
          () => _pickerError = 'The profile image must be 5 MB or smaller.',
        );
        return;
      }
      setState(() {
        _imageBytes = bytes;
        _imageFilename = file.name;
        _pickerError = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _pickerError =
              'Could not open that image. Please choose another one.',
        );
      }
    }
  }

  Future<void> _save() async {
    final profile = context.read<ProfileController>().profile;
    if (profile == null) return;
    final shopName = _shopController.text.trim();
    final realName = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final phoneDigits = phone.replaceAll(RegExp(r'\D'), '').length;
    if (shopName.isEmpty || realName.isEmpty || phone.isEmpty) {
      setState(
        () => _pickerError =
            'Shop name, full name, and phone number are required.',
      );
      return;
    }
    if (shopName.length > 100 || realName.length > 100 || phone.length > 20) {
      setState(
        () => _pickerError = 'One or more fields exceed the allowed length.',
      );
      return;
    }
    if (phoneDigits < 8 || phoneDigits > 15) {
      setState(
        () => _pickerError = 'Enter a phone number with 8 to 15 digits.',
      );
      return;
    }
    final success = await context.read<ProfileController>().save(
      shopName: shopName,
      realName: realName,
      phone: phone,
      imageBytes: _imageBytes,
      imageFilename: _imageFilename,
    );
    if (!mounted) return;
    if (success) {
      setState(() {
        _editing = false;
        _pickerError = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileController>(
      builder: (context, controller, _) {
        final profile = controller.profile;
        if (controller.isLoading && profile == null) {
          return const LoadingPanel();
        }
        if (profile == null) {
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              if (controller.errorMessage != null)
                ErrorBanner(controller.errorMessage!, onRetry: controller.load),
            ],
          );
        }
        final api = context.read<ApiService>();

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            SectionTitle(
              'Profile',
              subtitle: 'Manage your shop details and contact information.',
              trailing: TextButton.icon(
                onPressed: controller.isSaving
                    ? null
                    : _editing
                    ? _save
                    : () => _startEditing(profile),
                icon: Icon(
                  _editing ? Icons.save_outlined : Icons.edit_outlined,
                ),
                label: Text(_editing ? 'Save' : 'Edit'),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 22,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: const Color(0xFFEAF3EF),
                          child: _imageBytes != null
                              ? ClipOval(
                                  child: Image.memory(
                                    _imageBytes!,
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.person,
                                      color: AppTheme.green,
                                      size: 42,
                                    ),
                                  ),
                                )
                              : profile.profileImage == null
                              ? const Icon(
                                  Icons.person,
                                  color: AppTheme.green,
                                  size: 42,
                                )
                              : ClipOval(
                                  child: Image.network(
                                    api.resolveMediaUrl(profile.profileImage!),
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.person,
                                      color: AppTheme.green,
                                      size: 42,
                                    ),
                                  ),
                                ),
                        ),
                        if (_editing)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: IconButton.filled(
                              onPressed: _pickProfileImage,
                              tooltip: 'Change profile photo',
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                size: 18,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.green,
                                minimumSize: const Size(34, 34),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _editing
                        ? TextField(
                            controller: _shopController,
                            maxLength: 100,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              labelText: 'Shop name',
                              counterText: '',
                            ),
                          )
                        : Text(
                            profile.shopName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 19,
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                    const SizedBox(height: 4),
                    Text(
                      profile.isAdmin ? 'Administrator' : 'MFU Market Vendor',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                  children: [
                    _profileField(
                      label: 'Full name',
                      value: profile.realName,
                      icon: Icons.badge_outlined,
                      controller: _nameController,
                    ),
                    const Divider(height: 24),
                    _profileField(
                      label: 'Phone number',
                      value: profile.phone,
                      icon: Icons.phone_outlined,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const Divider(height: 24),
                    _profileField(
                      label: 'Username',
                      value: profile.username,
                      icon: Icons.person_outline,
                      editable: false,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEAF3EF),
                  child: Icon(Icons.lock_outline, color: AppTheme.green),
                ),
                title: const Text(
                  'Password',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text('Update your account password.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final changed = await showChangePasswordDialog(context);
                  if (changed == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully.'),
                      ),
                    );
                  }
                },
              ),
            ),
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 12),
              ErrorBanner(controller.errorMessage!),
            ],
            if (_pickerError != null) ...[
              const SizedBox(height: 12),
              ErrorBanner(_pickerError!),
            ],
            if (_editing) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: controller.isSaving
                    ? null
                    : () => setState(() {
                        _editing = false;
                        _imageBytes = null;
                        _imageFilename = null;
                        _pickerError = null;
                      }),
                child: const Text('Discard Changes'),
              ),
            ],
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => context.read<AuthController>().logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.muted),
            ),
          ],
        );
      },
    );
  }

  Widget _profileField({
    required String label,
    required String value,
    required IconData icon,
    TextEditingController? controller,
    TextInputType? keyboardType,
    bool editable = true,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.muted, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: _editing && editable
              ? TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLength: label == 'Phone number' ? 20 : 100,
                  decoration: InputDecoration(
                    labelText: label,
                    isDense: true,
                    border: InputBorder.none,
                    counterText: '',
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
