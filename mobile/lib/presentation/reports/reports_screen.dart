import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/reports_provider.dart';
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
          onRefresh: () => provider.load(),
          child: Builder(
            builder: (context) {
              if (provider.isLoading && provider.weeklyReport == null) {
                return const LoadingView();
              }
              if (provider.errorMessageAr != null && provider.weeklyReport == null) {
                return ErrorView(messageAr: provider.errorMessageAr!, onRetry: () => provider.load());
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (provider.weeklyReport != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(AppStrings.weeklyReport, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 8),
                            Text(
                              provider.weeklyReport!.summaryAr,
                              style: const TextStyle(height: 1.6, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(AppStrings.moodTrend, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 12),
                          MoodTrendChart(points: provider.moodTrend),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(AppStrings.riskProgression, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 12),
                          RiskProgressionChart(points: provider.riskProgression),
                        ],
                      ),
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
