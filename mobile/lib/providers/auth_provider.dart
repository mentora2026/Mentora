import 'package:flutter/foundation.dart';

import '../data/models/user.dart';
import '../data/repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  AuthStatus status = AuthStatus.unknown;
  AppUser? currentUser;
  String? errorMessageAr;
  bool isLoading = false;

  Future<void> checkAuthStatus() async {
    final loggedIn = await _authRepository.isLoggedIn();
    if (!loggedIn) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      currentUser = await _authRepository.getCurrentUser();
      status = AuthStatus.authenticated;
    } catch (_) {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    isLoading = true;
    errorMessageAr = null;
    notifyListeners();

    try {
      await _authRepository.login(email: email, password: password);
      currentUser = await _authRepository.getCurrentUser();
      status = AuthStatus.authenticated;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessageAr = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    isLoading = true;
    errorMessageAr = null;
    notifyListeners();

    try {
      await _authRepository.register(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
      currentUser = null;
      status = AuthStatus.unauthenticated;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessageAr = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
