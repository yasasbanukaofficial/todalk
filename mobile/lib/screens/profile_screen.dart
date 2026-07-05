import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.lavender.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (user?.name.isNotEmpty == true
                            ? user!.name[0]
                            : '?')
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lavender,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.name ?? 'User',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              if (user?.email.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  user!.email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              _SettingsRow(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () {},
              ),
              _SettingsRow(
                icon: Icons.palette_outlined,
                label: 'Theme',
                onTap: () {},
              ),
              _SettingsRow(
                icon: Icons.info_outline,
                label: 'About',
                onTap: () {},
              ),
              const Divider(height: 1, color: AppColors.lightGrey),
              _SettingsRow(
                icon: Icons.logout,
                label: 'Log out',
                isDestructive: true,
                onTap: () {
                  context.read<AuthProvider>().logout();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/auth',
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(
            icon,
            color: isDestructive ? AppColors.red : AppColors.grey,
            size: 22,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDestructive ? AppColors.red : AppColors.white,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.grey,
            size: 22,
          ),
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(height: 1, color: AppColors.lightGrey),
      ],
    );
  }
}
