import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: text.labelSmall?.copyWith(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
              color: AppColors.muted),
        ),
        const SizedBox(height: 6),
        Text(title,
            style: text.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800, height: 1.1)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: text.bodyMedium?.copyWith(color: AppColors.muted)),
      ],
    );
  }
}
