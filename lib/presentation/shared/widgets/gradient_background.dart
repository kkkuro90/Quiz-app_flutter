import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool showGradient;

  const GradientBackground({
    super.key,
    required this.child,
    this.showGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showGradient) {
      return Container(
        color: AppColors.background,
        child: child,
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundGradientStart,
            AppColors.backgroundGradientEnd,
          ],
        ),
      ),
      child: child,
    );
  }
}

