import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _requestedLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requestedLoad) {
      _requestedLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<AdminController>().loadUsers();
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lock_reset, color: Color(0xFFB83A4B)),
        title: const Text('Reset Password'),
        content: Text(
          'Reset ${user.username}’s password to the temporary password 123456?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB83A4B),
            ),
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<AdminController>().resetPassword(user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password reset for ${user.username}. Temporary password: 123456.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        final controller = context.read<AdminController>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              controller.errorMessage ?? 'Could not reset the password.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminController>(
      builder: (context, controller, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              child: Column(
                children: [
                  const SectionTitle(
                    'Manage Users',
                    subtitle: 'Search vendors and reset passwords.',
                  ),
                  const SizedBox(height: 13),
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: (query) {
                      _searchDebounce?.cancel();
                      _searchDebounce = Timer(
                        const Duration(milliseconds: 300),
                        () => controller.loadUsers(query: query),
                      );
                    },
                    onSubmitted: (query) {
                      _searchDebounce?.cancel();
                      controller.loadUsers(query: query);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by shop, username, or phone',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Search',
                        onPressed: () {
                          _searchDebounce?.cancel();
                          controller.loadUsers(query: _searchController.text);
                        },
                        icon: const Icon(Icons.arrow_forward),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (controller.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: ErrorBanner(controller.errorMessage!),
              ),
            Expanded(
              child: controller.isLoadingUsers && controller.users.isEmpty
                  ? const LoadingPanel()
                  : controller.users.isEmpty
                  ? const Center(
                      child: Text(
                        'No vendors found.',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          controller.loadUsers(query: _searchController.text),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
                        itemCount: controller.users.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 9),
                        itemBuilder: (context, index) {
                          final user = controller.users[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user.shopName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppTheme.ink,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${user.realName} · ${user.phone}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppTheme.muted,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 9),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F3),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          user.role.toUpperCase(),
                                          style: const TextStyle(
                                            color: AppTheme.muted,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'User: ${user.username}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppTheme.muted,
                                            fontSize: 10,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _resetPassword(user),
                                        icon: const Icon(
                                          Icons.refresh,
                                          size: 14,
                                        ),
                                        label: const Text('Reset password'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFFB83A4B,
                                          ),
                                          backgroundColor: const Color(
                                            0xFFFFF1F2,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 7,
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
