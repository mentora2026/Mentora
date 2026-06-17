import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/extras.dart';
import '../../providers/recommendation_provider.dart';
import '../shared/app_card.dart';
import '../shared/section_header.dart';
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
          color: AppColors.primary,
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
                  icon: Icons.lightbulb_outline_rounded,
                );
              }

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  SectionHeader(
                    title: AppStrings.recommendations,
                    subtitle: "توصيات مخصّصة بناءً على حالتك — اضغط لقراءة التفاصيل",
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...provider.recommendations.map((rec) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _RecommendationCard(recommendation: rec),
                      )),
                ],
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
    final accentColor = isCrisisCategory ? AppColors.risk5 : AppColors.primary;

    return AppCard(
      color: isCrisisCategory ? AppColors.risk5.withValues(alpha: 0.04) : AppColors.surface,
      borderSide: isCrisisCategory
          ? BorderSide(color: AppColors.risk5.withValues(alpha: 0.25))
          : null,
      onTap: () {
        setState(() => _expanded = !_expanded);
        if (_expanded) context.read<RecommendationProvider>().markViewed(rec);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CategoryIcon(category: rec.recommendation.category, accentColor: accentColor),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rec.recommendation.titleAr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.expand_more_rounded, color: AppColors.textTertiary),
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(color: AppColors.border.withValues(alpha: 0.7), height: 1),
            const SizedBox(height: AppSpacing.md),
            Text(
              rec.recommendation.contentAr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.65, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            if (rec.isHelpfulFeedback == null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.wasThisHelpful,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
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
                ),
              )
            else
              Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: AppColors.risk1, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    AppStrings.thankYouForFeedback,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final String category;
  final Color accentColor;

  const _CategoryIcon({required this.category, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final iconData = switch (category) {
      "breathing_exercise" => Icons.air_rounded,
      "relaxation" => Icons.self_improvement_rounded,
      "sleep_tip" => Icons.bedtime_outlined,
      "stress_management" => Icons.spa_outlined,
      "motivational" => Icons.emoji_events_outlined,
      "educational" => Icons.menu_book_outlined,
      "professional_help" => Icons.support_agent_rounded,
      _ => Icons.lightbulb_outline_rounded,
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Icon(iconData, color: accentColor, size: 22),
    );
  }
}
