/// Persian numeral rendering — a small detail with a large authenticity signal
/// (Visual Report §3.4).
const _faDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

extension StringX on String {
  String get toPersianDigits =>
      replaceAllMapped(RegExp(r'[0-9]'), (m) => _faDigits[int.parse(m[0]!)]);

  bool get isBlank => trim().isEmpty;
}

extension IntX on int {
  String get toPersianDigits => toString().toPersianDigits;
}
