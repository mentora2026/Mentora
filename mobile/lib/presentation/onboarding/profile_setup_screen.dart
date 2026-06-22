import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../data/models/user.dart';
import '../../providers/profile_provider.dart';
import '../shared/state_views.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool isEditMode;
  final VoidCallback? onCompleted;

  const ProfileSetupScreen({super.key, this.isEditMode = false, this.onCompleted});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _diseaseDurationController = TextEditingController();
  final _sleepHoursController = TextEditingController();
  final _medicalBackgroundController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String? _activityLevel;
  String? _socialSupportLevel;
  String? _gender;
  DateTime? _dateOfBirth;
  List<String> _selectedMedications = [];

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
      if (profile.sleepHoursAvg != null) {
        _sleepHoursController.text = profile.sleepHoursAvg!.toString();
      }
      if (profile.heightCm != null) {
        _heightController.text = profile.heightCm!.toString();
      }
      if (profile.weightKg != null) {
        _weightController.text = profile.weightKg!.toString();
      }
      if (profile.dateOfBirth != null) {
        _dateOfBirth = DateTime.tryParse(profile.dateOfBirth!);
      }
      
      _medicalBackgroundController.text = profile.medicalBackground ?? "";
      _activityLevel = profile.activityLevel;
      _socialSupportLevel = profile.socialSupportLevel;
      _gender = profile.gender;
      _selectedMedications = List.from(profile.medications);
    });
  }

  @override
  void dispose() {
    _diseaseDurationController.dispose();
    _sleepHoursController.dispose();
    _medicalBackgroundController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final provider = context.read<ProfileProvider>();
    final success = await provider.updateProfile(
      dateOfBirth: _dateOfBirth?.toIso8601String().split('T')[0],
      gender: _gender,
      heightCm: num.tryParse(_heightController.text),
      weightKg: num.tryParse(_weightController.text),
      diseaseDurationMonths: num.tryParse(_diseaseDurationController.text),
      medications: _selectedMedications,
      sleepHoursAvg: num.tryParse(_sleepHoursController.text),
      activityLevel: _activityLevel,
      socialSupportLevel: _socialSupportLevel,
      medicalBackground: _medicalBackgroundController.text.trim().isEmpty
          ? null
          : _medicalBackgroundController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.profileSaved)));
      if (widget.onCompleted != null) {
        widget.onCompleted!();
      } else if (widget.isEditMode) {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessageAr ?? AppStrings.somethingWentWrong)),
      );
    }
  }

  void _showMedicationsDialog(ProfileProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return _MedicationsDialog(
          allMedications: provider.allMedications,
          initialSelection: _selectedMedications,
          onSave: (selected) {
            setState(() {
              _selectedMedications = selected;
            });
          },
        );
      },
    );
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
          
          const Text('البيانات الشخصية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dateOfBirth ?? DateTime(1990),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _dateOfBirth = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'تاريخ الميلاد'),
                    child: Text(
                      _dateOfBirth != null ? "${_dateOfBirth!.year}-${_dateOfBirth!.month}-${_dateOfBirth!.day}" : "اختر التاريخ",
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(labelText: 'الجنس'),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('ذكر')),
                    DropdownMenuItem(value: 'female', child: Text('أنثى')),
                  ],
                  onChanged: (val) => setState(() => _gender = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الطول (سم)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الوزن (كجم)'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Text('البيانات الصحية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          TextField(
            controller: _diseaseDurationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: AppStrings.diseaseDuration),
          ),
          const SizedBox(height: 16),
          
          InkWell(
            onTap: () => _showMedicationsDialog(provider),
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'الأدوية الحالية'),
              child: Text(
                _selectedMedications.isEmpty 
                    ? "اختر الأدوية أو أضف دواء جديد" 
                    : _selectedMedications.join('، '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
            items: AppStrings.activityLevels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (value) => setState(() => _activityLevel = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _socialSupportLevel,
            decoration: const InputDecoration(labelText: AppStrings.socialSupport),
            items: AppStrings.socialSupportLevels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
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
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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

class _MedicationsDialog extends StatefulWidget {
  final List<Medication> allMedications;
  final List<String> initialSelection;
  final ValueChanged<List<String>> onSave;

  const _MedicationsDialog({
    required this.allMedications,
    required this.initialSelection,
    required this.onSave,
  });

  @override
  State<_MedicationsDialog> createState() => _MedicationsDialogState();
}

class _MedicationsDialogState extends State<_MedicationsDialog> {
  final Set<String> _selected = {};
  final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initialSelection);
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _addCustom() {
    final val = _customController.text.trim();
    if (val.isNotEmpty) {
      setState(() {
        _selected.add(val);
        _customController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('الأدوية المضافة'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customController,
                    decoration: const InputDecoration(
                      hintText: 'إضافة دواء غير موجود بالقائمة',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _addCustom,
                  color: Theme.of(context).primaryColor,
                )
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: widget.allMedications.map((m) {
                  final isSelected = _selected.contains(m.nameAr) || _selected.contains(m.nameEn);
                  return CheckboxListTile(
                    title: Text(m.nameAr),
                    subtitle: m.genericName != null ? Text(m.genericName!, style: const TextStyle(fontSize: 12)) : null,
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selected.add(m.nameAr);
                        } else {
                          _selected.remove(m.nameAr);
                          _selected.remove(m.nameEn);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            if (_selected.where((s) => !widget.allMedications.any((m) => m.nameAr == s || m.nameEn == s)).isNotEmpty) ...[
              const Divider(),
              const Text('أدوية مضافة يدوياً:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Wrap(
                spacing: 4,
                children: _selected
                    .where((s) => !widget.allMedications.any((m) => m.nameAr == s || m.nameEn == s))
                    .map((s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 12)),
                          onDeleted: () => setState(() => _selected.remove(s)),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            widget.onSave(_selected.toList());
            Navigator.pop(context);
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
