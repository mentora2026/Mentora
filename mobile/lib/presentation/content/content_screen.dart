import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/content_provider.dart';
import '../shared/app_card.dart';
import '../shared/state_views.dart';

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.contentLibrary),
      ),
      body: Consumer<ContentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && (provider.items == null || provider.items!.isEmpty)) {
            return const LoadingView();
          }

          if (provider.errorMessageAr != null && (provider.items == null || provider.items!.isEmpty)) {
            return ErrorView(
              messageAr: provider.errorMessageAr!,
              onRetry: provider.load,
            );
          }

          if (provider.items != null && provider.items!.isEmpty) {
            return const EmptyView(
              icon: Icons.menu_book_rounded,
              messageAr: AppStrings.noContentAvailable,
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: provider.load,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: provider.items?.length ?? 0,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = provider.items![index];
                return AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      item.titleAr ?? "محتوى توعوي",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Row(
                        children: [
                          Icon(
                            _getIconForType(item.contentType),
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            _getLabelForType(item.contentType),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    children: [
                      const Divider(height: 1, color: AppColors.border),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            item.bodyAr,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'article':
        return Icons.article_outlined;
      case 'tip':
        return Icons.lightbulb_outline;
      case 'video':
        return Icons.play_circle_outline;
      default:
        return Icons.library_books_outlined;
    }
  }

  String _getLabelForType(String type) {
    switch (type) {
      case 'article':
        return 'مقال علمي';
      case 'tip':
        return 'نصيحة';
      case 'video':
        return 'فيديو';
      default:
        return 'محتوى توعوي';
    }
  }
}
