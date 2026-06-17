import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/assessment.dart';
import '../../providers/mood_provider.dart';
import '../shared/app_card.dart';
import '../shared/section_header.dart';
import '../shared/state_views.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  int _selectedMood = 3;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MoodProvider>().load();
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<MoodProvider>();
    final success = await provider.addEntry(
      moodValue: _selectedMood,
      noteAr: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      _noteController.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(AppStrings.moodSaved)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(provider.errorMessageAr ?? AppStrings.somethingWentWrong)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoodProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.moodTracker)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.load(),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _MoodSummaryCard(entries: provider.entries),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: AppStrings.howIsYourMood,
                      subtitle:
                          'اختر أقرب شعور لك الآن، ويمكنك إضافة ملاحظة قصيرة',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: List.generate(5, (index) {
                        final value = index + 1;
                        return Expanded(
                          child: _MoodChoice(
                            value: value,
                            isSelected: _selectedMood == value,
                            onTap: () => setState(() => _selectedMood = value),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: AppStrings.addNote,
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: provider.isSaving ? null : _save,
                      icon: provider.isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_rounded),
                      label: const Text(AppStrings.saveMood),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(
                title: AppStrings.moodHistory,
                subtitle: 'آخر الحالات المسجلة لمتابعة التغيرات اليومية',
              ),
              if (provider.isLoading)
                const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: LoadingView())
              else if (provider.entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: EmptyView(
                      messageAr: AppStrings.noDataYet,
                      icon: Icons.mood_outlined),
                )
              else
                ...provider.entries
                    .map((entry) => _MoodHistoryTile(entry: entry)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodSummaryCard extends StatelessWidget {
  final List<MoodEntry> entries;

  const _MoodSummaryCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final latest = entries.isNotEmpty ? entries.first : null;
    final average = entries.isEmpty
        ? null
        : entries
                .take(7)
                .map((entry) => entry.moodValue)
                .reduce((a, b) => a + b) /
            entries.take(7).length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                latest == null ? '—' : _moodEmoji(latest.moodValue),
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  latest == null
                      ? 'ابدأ بتسجيل حالتك اليوم'
                      : AppStrings.moodLabels[latest.moodValue] ?? '',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  average == null
                      ? 'التسجيل اليومي يساعدك على ملاحظة النمط بوضوح'
                      : 'متوسط آخر 7 سجلات: ${average.toStringAsFixed(1)} من 5',
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

class _MoodChoice extends StatelessWidget {
  final int value;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodChoice(
      {required this.value, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _moodColor(value);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.16)
                : AppColors.surfaceMuted.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
                color: isSelected ? color : AppColors.border,
                width: isSelected ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Text(_moodEmoji(value), style: const TextStyle(fontSize: 24)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppStrings.moodLabels[value] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodHistoryTile extends StatelessWidget {
  final MoodEntry entry;

  const _MoodHistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = _moodColor(entry.moodValue);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Center(
                child: Text(_moodEmoji(entry.moodValue),
                    style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.moodLabels[entry.moodValue] ?? '',
                    style: Theme.of(context).textTheme.titleSmall),
                if (entry.noteAr != null &&
                    entry.noteAr!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(entry.noteAr!,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            DateFormat('d/M HH:mm').format(entry.recordedAt),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

Color _moodColor(int value) {
  if (value <= 2) return AppColors.moodLow;
  if (value == 3) return AppColors.moodMid;
  return AppColors.moodHigh;
}

String _moodEmoji(int value) {
  switch (value) {
    case 1:
      return '😞';
    case 2:
      return '🙁';
    case 3:
      return '😐';
    case 4:
      return '🙂';
    case 5:
      return '😄';
    default:
      return '🙂';
  }
}
