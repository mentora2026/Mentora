import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../data/models/user.dart';
import '../../providers/profile_provider.dart';
import '../shared/state_views.dart';

class ProfileSetupScreen extends StatefulWidget {
  /// If true, shows an AppBar with a back button (edit mode from Profile tab).
  /// If false, this is part of the onboarding flow (no back navigation).
  final bool isEditMode;
  final VoidCallback? onCompleted;

  const ProfileSetupScreen({super.key, this.isEditMode = false, this.onCompleted});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _diseaseDurationController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _sleepHoursController = TextEditingController();
  final _medicalBackgroundController = TextEditingController();

  String? _activityLevel;
  String? _socialSupportLevel;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ProfileProvider>();
      await provider.load();
      _populateFromProfile(provider.profile);
    });
  }

  void _populateFromProfile(PatientProfile? profile) {
    if (profile == null || _initialized) return;
    _initialized = true;

    setState(() {
      if (profile.diseaseDurationMonths != null) {
        _diseaseDurationController.text = profile.diseaseDurationMonths!.toString();
      }
      _medicationsController.text = profile.medications ?? "";
      if (profile.sleepHoursAvg != null) {
        _sleepHoursController.text = profile.sleepHoursAvg!.toString();
      }
      _medicalBackgroundController.text = profile.medicalBackground ?? "";
      _activityLevel = profile.activityLevel;
      _socialSupportLevel = profile.socialSupportLevel;
    });
  }

  @override
  void dispose() {
    _diseaseDurationController.dispose();
    _medicationsController.dispose();
    _sleepHoursController.dispose();
    _medicalBackgroundController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final provider = context.read<ProfileProvider>();
    final success = await provider.updateProfile(
      diseaseDurationMonths: num.tryParse(_diseaseDurationController.text),
      medications: _medicationsController.text.trim().isEmpty ? null : _medicationsController.text.trim(),
      sleepHoursAvg: num.tryParse(_sleepHoursController.text),
      activityLevel: _activityLevel,
      socialSupportLevel: _socialSupportLevel,
      medicalBackground:
          _medicalBackgroundController.text.trim().isEmpty ? null : _medicalBackgroundController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.profileSaved)));
      widget.onCompleted?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessageAr ?? AppStrings.somethingWentWrong)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();

    if (provider.isLoading && provider.profile == null) {
      return const Scaffold(body: LoadingView());
    }

    if (provider.errorMessageAr != null && provider.profile == null) {
      return Scaffold(
        body: ErrorView(messageAr: provider.errorMessageAr!, onRetry: () => provider.load()),
      );
    }

    _populateFromProfile(provider.profile);

    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.isEditMode) ...[
            const SizedBox(height: 8),
            Text(
              AppStrings.profileSetupTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "ساعدنا في فهم حالتك بشكل أفضل لتقديم محادثات ودعم أكثر تخصصاً.",
              style: TextStyle(color: Color(0xFF6F6F6F)),
            ),
            const SizedBox(height: 24),
          ],
          _ConditionsSection(provider: provider),
          const SizedBox(height: 20),
          TextField(
            controller: _diseaseDurationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: AppStrings.diseaseDuration),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _medicationsController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: AppStrings.medications),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sleepHoursController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: AppStrings.sleepHours),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _activityLevel,
            decoration: const InputDecoration(labelText: AppStrings.activityLevel),
            items: AppStrings.activityLevels.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (value) => setState(() => _activityLevel = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _socialSupportLevel,
            decoration: const InputDecoration(labelText: AppStrings.socialSupport),
            items: AppStrings.socialSupportLevels.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (value) => setState(() => _socialSupportLevel = value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _medicalBackgroundController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: AppStrings.medicalBackground),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text(AppStrings.saveProfile),
          ),
          const SizedBox(height: 12),
          const Text(
            AppStrings.disclaimer,
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6F6F6F), fontSize: 12),
          ),
        ],
      ),
    );

    if (widget.isEditMode) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.editProfile)),
        body: SafeArea(child: body),
      );
    }

    return Scaffold(body: SafeArea(child: body));
  }
}

class _ConditionsSection extends StatelessWidget {
  final ProfileProvider provider;

  const _ConditionsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final myConditionIds = provider.profile?.conditions.map((c) => c.chronicCondition.id).toSet() ?? {};
    final available = provider.allConditions.where((c) => !myConditionIds.contains(c.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(AppStrings.chronicConditionsLabel, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
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
                onPressed: () => _showAddConditionSheet(context, available),
              ),
          ],
        ),
      ],
    );
  }

  void _showAddConditionSheet(BuildContext context, List<ChronicCondition> available) {
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
