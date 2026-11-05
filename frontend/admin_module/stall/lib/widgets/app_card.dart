import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(14),
    this.bordered = true,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: bordered ? Border.all(color: AppColors.border) : null,
      ),
      child: child,
    );
  }
}
