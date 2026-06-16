/// Exception thrown by [ApiClient] when the backend returns a non-2xx
/// response. Carries the Arabic `message_ar` / `detail` field from the
/// FastAPI error envelope when available, falling back to a generic
/// Arabic message otherwise.
class ApiException implements Exception {
  final int statusCode;
  final String messageAr;

  ApiException({required this.statusCode, required this.messageAr});

  @override
  String toString() => messageAr;
}

/// Thrown when the device has no network connectivity / the request times out.
class NetworkException implements Exception {
  final String messageAr;
  NetworkException([this.messageAr = "تعذر الاتصال بالخادم، تحقق من اتصال الإنترنت"]);

  @override
  String toString() => messageAr;
}

/// Thrown when the access token is missing/expired and refresh also failed.
class UnauthorizedException implements Exception {
  final String messageAr;
  UnauthorizedException([this.messageAr = "انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى"]);

  @override
  String toString() => messageAr;
}
