import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/interview_provider.dart';
import '../chat/chat_screen.dart';
import '../mood/mood_tracker_screen.dart';
import '../recommendations/recommendations_screen.dart';
import '../reports/reports_screen.dart';
import '../content/content_screen.dart';
import '../shared/app_card.dart';
import '../shared/risk_badge.dart';
import '../shared/risk_gauge.dart';
import '../shared/section_header.dart';
import '../shared/state_views.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().load();
    });
  }

  Future<void> _openChat() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ChatScreen()));
    if (mounted) context.read<HomeProvider>().load();
  }

  void _openScreen(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final interviewProvider = context.read<InterviewProvider>();
    final userName = authProvider.currentUser?.fullName ?? "";
    final hasActiveSession =
        interviewProvider.currentSession?.isInProgress == true;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => homeProvider.load(),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Welcome header
              Text(
                "${AppStrings.welcomeBack}، $userName",
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 22),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppStrings.howAreYouToday,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Risk status card
              AppCard(
                child: homeProvider.isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary)),
                      )
                    : homeProvider.latestRisk != null
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RiskGauge(
                                  riskLevel:
                                      homeProvider.latestRisk!.riskLevel),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SectionHeader(
                                      title: AppStrings.latestRiskLevel,
                                      subtitle: "بناءً على آخر جلسة تقييم",
                                    ),
                                    RiskLevelBadge(
                                        riskLevel:
                                            homeProvider.latestRisk!.riskLevel),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      homeProvider.latestRisk!.explanationAr,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(height: 1.6),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionHeader(
                                  title: AppStrings.latestRiskLevel),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.insights_outlined,
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.7)),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        AppStrings.noAssessmentYet,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(height: 1.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Primary CTA — interview
              QuickActionTile(
                prominent: true,
                icon: Icons.chat_bubble_outline_rounded,
                title: hasActiveSession
                    ? AppStrings.continueInterview
                    : AppStrings.startInterview,
                subtitle: "محادثة قصيرة تساعدنا على فهم حالتك بشكل أفضل",
                iconColor: Colors.white,
                iconBackground: Colors.white24,
                onTap: _openChat,
              ),

              const SizedBox(height: AppSpacing.sm),

              const SectionHeader(
                  title: "اختصارات سريعة",
                  subtitle: "الوصول السريع للأقسام الرئيسية"),
              const SizedBox(height: AppSpacing.xs),

              // Quick actions grid (2 columns)
              Row(
                children: [
                  Expanded(
                    child: _CompactAction(
                      icon: Icons.emoji_emotions_outlined,
                      label: AppStrings.quickMoodLog,
                      color: AppColors.secondary,
                      background: AppColors.secondaryLight,
                      onTap: () => _openScreen(const MoodTrackerScreen()),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _CompactAction(
                      icon: Icons.lightbulb_outline_rounded,
                      label: AppStrings.recommendations,
                      color: AppColors.accent,
                      background: AppColors.accent.withValues(alpha: 0.12),
                      onTap: () => _openScreen(const RecommendationsScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _CompactAction(
                      icon: Icons.bar_chart_rounded,
                      label: AppStrings.reports,
                      color: AppColors.primary,
                      background: AppColors.primaryLight,
                      onTap: () => _openScreen(const ReportsScreen()),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _CompactAction(
                      icon: Icons.menu_book_rounded,
                      label: AppStrings.contentLibrary,
                      color: AppColors.primary,
                      background: AppColors.primaryLight,
                      onTap: () => _openScreen(const ContentScreen()),
                    ),
                  ),
                ],
              ),

              if (homeProvider.errorMessageAr != null) ...[
                const SizedBox(height: AppSpacing.md),
                ErrorView(
                    messageAr: homeProvider.errorMessageAr!,
                    onRetry: () => homeProvider.load()),
              ],
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _CompactAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style:
                Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
