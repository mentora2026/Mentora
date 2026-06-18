num? jsonNumOrNull(Object? value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

num jsonNum(Object? value, {num fallback = 0}) {
  return jsonNumOrNull(value) ?? fallback;
}

int jsonInt(Object? value, {int fallback = 0}) {
  final parsed = jsonNumOrNull(value);
  return parsed?.toInt() ?? fallback;
}

Map<String, dynamic> jsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
  }
  return const {};
}
