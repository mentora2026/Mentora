import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/interview_provider.dart';
import '../chat/chat_screen.dart';
import '../mood/mood_tracker_screen.dart';
import '../shared/risk_badge.dart';
import '../shared/state_views.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().load();
    });
  }

  Future<void> _openChat() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatScreen()));
    if (mounted) context.read<HomeProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.currentUser?.fullName ?? "";

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.home)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => homeProvider.load(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                "${AppStrings.welcomeBack}، $userName",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(AppStrings.howAreYouToday, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),

              // Risk status card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(AppStrings.latestRiskLevel, style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (homeProvider.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (homeProvider.latestRisk != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RiskLevelBadge(riskLevel: homeProvider.latestRisk!.riskLevel, large: true),
                            const SizedBox(height: 12),
                            Text(
                              homeProvider.latestRisk!.explanationAr,
                              style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
                            ),
                          ],
                        )
                      else
                        const Text(AppStrings.noAssessmentYet, style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Start interview card
              Card(
                color: AppColors.primary,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _openChat,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.read<InterviewProvider>().currentSession?.isInProgress == true
                                    ? AppStrings.continueInterview
                                    : AppStrings.startInterview,
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "محادثة قصيرة تساعدنا على فهم حالتك بشكل أفضل",
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Quick mood log
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MoodTrackerScreen()));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.emoji_emotions_outlined, color: AppColors.primary, size: 32),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            AppStrings.quickMoodLog,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        Icon(Icons.arrow_back_ios, color: AppColors.textSecondary, size: 16),
                      ],
                    ),
                  ),
                ),
              ),

              if (homeProvider.errorMessageAr != null) ...[
                const SizedBox(height: 16),
                ErrorView(messageAr: homeProvider.errorMessageAr!, onRetry: () => homeProvider.load()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
