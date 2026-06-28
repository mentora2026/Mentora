import 'package:flutter/foundation.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../data/models/extras.dart';

class ContentProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;

  List<ContentLibraryItem>? items;
  bool isLoading = false;
  String? errorMessageAr;

  Future<void> load() async {
    isLoading = true;
    errorMessageAr = null;
    notifyListeners();

    try {
      final response = await _api.get(ApiConstants.contentLibrary);
      if (response is List) {
        items = response.map((e) => ContentLibraryItem.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        items = [];
      }
    } on ApiException catch (e) {
      errorMessageAr = e.messageAr;
    } catch (e) {
      errorMessageAr = "تعذر تحميل المحتوى التعليمي. يرجى المحاولة لاحقاً.";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
