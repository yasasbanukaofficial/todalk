import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isOutlined;

  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : AppColors.white,
          foregroundColor: isOutlined ? AppColors.textSecondary : AppColors.black,
          surfaceTintColor: Colors.transparent,
          side: isOutlined ? const BorderSide(color: AppColors.hairline, width: 1) : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: isOutlined ? 0 : 2,
            color: isOutlined ? AppColors.textSecondary : AppColors.black,
          ),
        ),
      ),
    );
  }
}
