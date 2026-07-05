import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BottomSheetContainer extends StatelessWidget {
  final Widget child;
  final double? height;

  const BottomSheetContainer({
    super.key,
    required this.child,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? MediaQuery.of(context).size.height * 0.55,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.sheetRadius),
          topRight: Radius.circular(AppTheme.sheetRadius),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
