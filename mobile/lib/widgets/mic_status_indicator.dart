import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MicStatusIndicator extends StatelessWidget {
  final double animationValue;
  final bool isActive;

  const MicStatusIndicator({
    super.key,
    required this.animationValue,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isActive ? Icons.mic : Icons.mic_off,
          color: isActive ? AppColors.white : AppColors.textSecondary,
          size: 20,
        ),
        const SizedBox(width: 10),
        ...List.generate(5, (index) {
          final delay = index * 0.13;
          final raw = (animationValue + delay) % 1.0;
          final barHeight = isActive
              ? 0.3 + sin(raw * pi * 3) * 0.5 + 0.2
              : 0.3;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              width: 3,
              height: 12 + barHeight * 14,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.white.withValues(alpha: 0.7 + barHeight * 0.3)
                    : AppColors.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ],
    );
  }
}
