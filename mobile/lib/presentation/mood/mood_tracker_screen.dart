import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/mood_provider.dart';
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
      noteAr: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      _noteController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.moodSaved)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessageAr ?? AppStrings.somethingWentWrong)),
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
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(AppStrings.howIsYourMood, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (index) {
                          final value = index + 1;
                          final isSelected = _selectedMood == value;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedMood = value),
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 52,
                                  height: 52,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? _moodColor(value) : AppColors.background,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? _moodColor(value) : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(_moodEmoji(value), style: const TextStyle(fontSize: 24)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  AppStrings.moodLabels[value] ?? "",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _noteController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: AppStrings.addNote),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: provider.isSaving ? null : _save,
                        child: provider.isSaving
                            ? const SizedBox(
                                height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text(AppStrings.saveMood),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(AppStrings.moodHistory, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              if (provider.isLoading)
                const Padding(padding: EdgeInsets.all(24), child: LoadingView())
              else if (provider.entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: EmptyView(messageAr: AppStrings.noDataYet, icon: Icons.mood_outlined),
                )
              else
                ...provider.entries.map((entry) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _moodColor(entry.moodValue).withValues(alpha: 0.2),
                          child: Text(_moodEmoji(entry.moodValue)),
                        ),
                        title: Text(AppStrings.moodLabels[entry.moodValue] ?? ""),
                        subtitle: entry.noteAr != null ? Text(entry.noteAr!) : null,
                        trailing: Text(
                          DateFormat("d/M HH:mm").format(entry.recordedAt),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Color _moodColor(int value) {
    if (value <= 2) return AppColors.moodLow;
    if (value == 3) return AppColors.moodMid;
    return AppColors.moodHigh;
  }

  String _moodEmoji(int value) {
    switch (value) {
      case 1:
        return "😞";
      case 2:
        return "🙁";
      case 3:
        return "😐";
      case 4:
        return "🙂";
      case 5:
        return "😄";
      default:
        return "🙂";
    }
  }
}
