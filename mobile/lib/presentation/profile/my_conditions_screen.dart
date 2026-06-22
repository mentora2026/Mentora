import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/user.dart';
import '../../providers/profile_provider.dart';

class MyConditionsScreen extends StatelessWidget {
  const MyConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final myConditionIds = provider.profile?.conditions.map((c) => c.chronicCondition.id).toSet() ?? {};
    final available = provider.allConditions.where((c) => !myConditionIds.contains(c.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.myConditions)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const Text(
              'تُستخدم هذه الأمراض لتخصيص المحادثة وتقديم توصيات أكثر دقة لحالتك.',
              style: TextStyle(color: Color(0xFF6F6F6F), height: 1.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final pc in provider.profile?.conditions ?? const <PatientCondition>[])
                  Chip(
                    label: Text(pc.chronicCondition.nameAr),
                    onDeleted: () => provider.removeCondition(pc.chronicCondition.id),
                    deleteIcon: const Icon(Icons.close, size: 18),
                  ),
                if (available.isNotEmpty)
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text(AppStrings.addCondition),
                    onPressed: () => _showAddConditionSheet(context, provider, available),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddConditionSheet(BuildContext context, ProfileProvider provider, List<ChronicCondition> available) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(AppStrings.chronicConditionsLabel, style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              for (final condition in available)
                ListTile(
                  title: Text(condition.nameAr),
                  subtitle: condition.descriptionAr != null ? Text(condition.descriptionAr!) : null,
                  onTap: () {
                    Navigator.of(context).pop();
                    provider.addCondition(condition.id);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
