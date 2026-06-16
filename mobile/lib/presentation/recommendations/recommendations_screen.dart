import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/extras.dart';
import '../../providers/recommendation_provider.dart';
import '../shared/state_views.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecommendationProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecommendationProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.recommendations)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.load(),
          child: Builder(
            builder: (context) {
              if (provider.isLoading && provider.recommendations.isEmpty) {
                return const LoadingView();
              }
              if (provider.errorMessageAr != null && provider.recommendations.isEmpty) {
                return ErrorView(messageAr: provider.errorMessageAr!, onRetry: () => provider.load());
              }
              if (provider.recommendations.isEmpty) {
                return const EmptyView(
                  messageAr: AppStrings.noRecommendations,
                  icon: Icons.lightbulb_outline,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.recommendations.length,
                itemBuilder: (context, index) {
                  final rec = provider.recommendations[index];
                  return _RecommendationCard(recommendation: rec);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatefulWidget {
  final PatientRecommendation recommendation;

  const _RecommendationCard({required this.recommendation});

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final rec = widget.recommendation;
    final categoryLabel = AppStrings.recommendationCategoryLabels[rec.recommendation.category] ?? "";
    final isCrisisCategory = rec.recommendation.category == "professional_help";

    return Card(
      color: isCrisisCategory ? AppColors.risk5.withValues(alpha: 0.06) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() => _expanded = !_expanded);
          if (!_expanded) return;
          context.read<RecommendationProvider>().markViewed(rec);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CategoryIcon(category: rec.recommendation.category),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryLabel,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          rec.recommendation.titleAr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textSecondary),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                Text(rec.recommendation.contentAr, style: const TextStyle(height: 1.6)),
                const SizedBox(height: 16),
                if (rec.isHelpfulFeedback == null)
                  Row(
                    children: [
                      const Text(AppStrings.wasThisHelpful, style: TextStyle(color: AppColors.textSecondary)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.thumb_up_outlined),
                        color: AppColors.primary,
                        onPressed: () => context.read<RecommendationProvider>().submitFeedback(rec, true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.thumb_down_outlined),
                        color: AppColors.textSecondary,
                        onPressed: () => context.read<RecommendationProvider>().submitFeedback(rec, false),
                      ),
                    ],
                  )
                else
                  const Text(
                    AppStrings.thankYouForFeedback,
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final String category;

  const _CategoryIcon({required this.category});

  @override
  Widget build(BuildContext context) {
    final iconData = switch (category) {
      "breathing_exercise" => Icons.air,
      "relaxation" => Icons.self_improvement,
      "sleep_tip" => Icons.bedtime_outlined,
      "stress_management" => Icons.spa_outlined,
      "motivational" => Icons.emoji_events_outlined,
      "educational" => Icons.menu_book_outlined,
      "professional_help" => Icons.support_agent,
      _ => Icons.lightbulb_outline,
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
      child: Icon(iconData, color: AppColors.primary, size: 22),
    );
  }
}
