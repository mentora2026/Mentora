import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/home_provider.dart';
import '../onboarding/profile_setup_screen.dart';
import '../auth/change_password_screen.dart';
import 'my_conditions_screen.dart';
import '../shared/app_card.dart';
import '../shared/section_header.dart';
import '../shared/risk_badge.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancel)),
          FilledButton.tonal(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(AppStrings.logout)),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final homeProvider = context.watch<HomeProvider>();

    final user = authProvider.currentUser;
    final name = user?.fullName.trim().isNotEmpty == true ? user!.fullName : 'مستخدم المنصة';
    final email = user?.email ?? '';

    // Calculate age
    int? age;
    if (profileProvider.profile?.dateOfBirth != null) {
      final dob = DateTime.tryParse(profileProvider.profile!.dateOfBirth!);
      if (dob != null) {
        final now = DateTime.now();
        age = now.year - dob.year;
        if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
          age--;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _ProfileHero(name: name, email: email),
            const SizedBox(height: AppSpacing.lg),
            
            // Quick Status
            if (profileProvider.profile != null) ...[
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      icon: Icons.cake_outlined,
                      label: 'العمر',
                      value: age != null ? '$age سنة' : '-',
                    ),
                    _StatItem(
                      icon: Icons.height_outlined,
                      label: 'الطول',
                      value: profileProvider.profile!.heightCm != null ? '${profileProvider.profile!.heightCm} سم' : '-',
                    ),
                    _StatItem(
                      icon: Icons.monitor_weight_outlined,
                      label: 'الوزن',
                      value: profileProvider.profile!.weightKg != null ? '${profileProvider.profile!.weightKg} كجم' : '-',
                    ),
                    _StatItem(
                      icon: Icons.medication_outlined,
                      label: 'الأدوية',
                      value: '${profileProvider.profile!.medications.length}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            if (homeProvider.latestRisk != null) ...[
              AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Text('آخر مستوى خطر تم تسجيله:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    RiskLevelBadge(riskLevel: homeProvider.latestRisk!.riskLevel),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            const SectionHeader(
              title: 'إدارة الحساب',
              subtitle: 'تحكم ببياناتك وإعدادات تجربتك داخل المنصة',
            ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ProfileActionTile(
                    icon: Icons.manage_accounts_outlined,
                    title: AppStrings.editProfile,
                    subtitle: 'تحديث البيانات الصحية والشخصية',
                    iconColor: AppColors.primary,
                    iconBackground: AppColors.primaryLight,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileSetupScreen(isEditMode: true)),
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _ProfileActionTile(
                    icon: Icons.health_and_safety_outlined,
                    title: AppStrings.myConditions,
                    subtitle: 'تُستخدم لتخصيص المحادثة والتوصيات',
                    iconColor: AppColors.secondary,
                    iconBackground: AppColors.secondaryLight,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyConditionsScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _ProfileActionTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'تغيير كلمة المرور',
                    subtitle: 'تحديث كلمة المرور لحسابك',
                    iconColor: AppColors.accent,
                    iconBackground: AppColors.accent.withValues(alpha: 0.12),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'حول التطبيق'),
            AppCard(
              color: AppColors.surfaceElevated,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: AppColors.accent),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          AppStrings.disclaimer,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Center(
                    child: Text(
                      'الإصدار 1.0.0',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text(AppStrings.logout),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.risk5,
                side: BorderSide(color: AppColors.risk5.withValues(alpha: 0.35)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final String name;
  final String email;

  const _ProfileHero({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0] : '';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Text(
              initial,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  email,
                  textDirection: TextDirection.ltr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback onTap;

  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ),
      trailing: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }
}
