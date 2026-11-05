import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
                color: AppColors.greenSoft, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: AppColors.green),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ),
          Text(label, style: text.bodySmall?.copyWith(color: AppColors.muted)),
        ],
      ),
    );
  }
}
