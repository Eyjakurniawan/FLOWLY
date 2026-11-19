import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class FlowlyLogo extends StatelessWidget {
  final double size;
  final Color color;

  const FlowlyLogo({
    super.key,
    this.size = 22,
    this.color = AppColors.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      AppConstants.appName,
      style: AppTheme.logo(size: size, color: color),
    );
  }
}
