/// Centralised date parsing so wire formats never leak into features.
extension DateTimeX on DateTime {
  String get toIso => toUtc().toIso8601String();
}

DateTime? parseIsoOrNull(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toLocal();
}
