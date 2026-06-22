import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/token_storage.dart';
import '../models/user.dart';

class AuthRepository {
  final ApiClient _client = ApiClient.instance;
  final TokenStorage _tokenStorage = TokenStorage.instance;

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    final response = await _client.post(
      ApiConstants.register,
      withAuth: false,
      body: {
        "email": email,
        "password": password,
        "full_name": fullName,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          "phone_number": phoneNumber,
      },
    );
    // The backend returns tokens after registration, but the app intentionally
    // sends new users back to the login screen so the flow is explicit.
    response as Map<String, dynamic>;
    await _tokenStorage.clear();
  }

  Future<void> login({required String email, required String password}) async {
    final response = await _client.post(
      ApiConstants.login,
      withAuth: false,
      body: {"email": email, "password": password},
    await _saveTokens(response as Map<String, dynamic>);
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await _client.post(
      ApiConstants.changePassword,
      body: {"current_password": currentPassword, "new_password": newPassword},
    );
  }

  Future<void> logout() async {
    try {
      await _client.post(ApiConstants.logout);
    } catch (_) {
      // Ignore network errors on logout - we clear local tokens regardless.
    }
    await _tokenStorage.clear();
  }

  Future<AppUser> getCurrentUser() async {
    final response = await _client.get(ApiConstants.me);
    return AppUser.fromJson(response as Map<String, dynamic>);
  }

  Future<bool> isLoggedIn() => _tokenStorage.hasTokens();

  Future<void> _saveTokens(Map<String, dynamic> response) async {
    await _tokenStorage.saveTokens(
      accessToken: response["access_token"] as String,
      refreshToken: response["refresh_token"] as String,
    );
  }
}
