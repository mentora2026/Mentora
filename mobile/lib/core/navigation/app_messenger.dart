import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppMessenger {
  AppMessenger._();

  static final key = GlobalKey<ScaffoldMessengerState>();

  static void showSuccess(String message) {
    key.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.primary,
        ),
      );
  }
}
