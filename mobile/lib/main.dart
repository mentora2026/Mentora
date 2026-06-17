import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/localization/app_strings.dart';
import 'core/navigation/app_messenger.dart';
import 'core/theme/app_theme.dart';
import 'presentation/shared/auth_gate.dart';
import 'providers/auth_provider.dart';
import 'providers/home_provider.dart';
import 'providers/interview_provider.dart';
import 'providers/mood_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/recommendation_provider.dart';
import 'providers/reports_provider.dart';

void main() {
  runApp(const PsychSupportApp());
}

class PsychSupportApp extends StatelessWidget {
  const PsychSupportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => InterviewProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: AppMessenger.key,
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,

        // ------------------------------------------------------------
        // Localization: Arabic is the only supported locale, per the
        // project's language rule (all user-facing content in Arabic).
        // This also configures RTL layout app-wide via Directionality.
        // ------------------------------------------------------------
        locale: const Locale("ar"),
        supportedLocales: const [Locale("ar")],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },

        home: const AuthGate(),
      ),
    );
  }
}
