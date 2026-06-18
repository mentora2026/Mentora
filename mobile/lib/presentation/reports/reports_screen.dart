import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/reports_provider.dart';
import '../shared/app_card.dart';
import '../shared/risk_gauge.dart';
import '../shared/section_header.dart';
import '../shared/state_views.dart';
import 'widgets/mood_trend_chart.dart';
import 'widgets/risk_progression_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.reports)),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => provider.load(),
          child: Builder(
            builder: (context) {
              if (provider.isLoading && provider.weeklyReport == null) {
                return const LoadingView();
              }
              if (provider.errorMessageAr != null &&
                  provider.weeklyReport == null) {
                return ErrorView(
                    messageAr: provider.errorMessageAr!,
                    onRetry: () => provider.load());
              }

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (provider.weeklyReport != null)
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: AppStrings.weeklyReport,
                            subtitle: "ملخص أسبوعي لحالتك النفسية",
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryLight.withValues(alpha: 0.5),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1)),
                            ),
                            child: Text(
                              provider.weeklyReport!.summaryAr,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    height: 1.65,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          title: AppStrings.moodTrend,
                          subtitle: "مقياس 1 (منخفض) → 5 (مرتفع)",
                        ),
                        MoodTrendChart(points: provider.moodTrend),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          title: AppStrings.riskProgression,
                          subtitle: "تطور مستوى الخطر عبر الجلسات",
                        ),
                        const RiskLevelLegend(),
                        const SizedBox(height: AppSpacing.md),
                        RiskProgressionChart(points: provider.riskProgression),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
