String? readJsonString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}
