/// The user's profile as the backend reports it (scope §16).
class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.birthMonth,
    required this.onboardingCompleted,
    this.personalizationOptOut = false,
  });

  final String? displayName;

  /// Shared enum name (FARVARDIN…ESFAND) or null before onboarding.
  final String? birthMonth;
  final bool onboardingCompleted;

  /// Scope §4: when true nothing is tailored and nothing is suggested. Kept on
  /// the server, so switching it off once switches it off on every device.
  final bool personalizationOptOut;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      displayName: json['displayName'] as String?,
      birthMonth: json['birthMonth'] as String?,
      onboardingCompleted: json['onboardingCompleted'] == true,
      personalizationOptOut: json['personalizationOptOut'] == true,
    );
  }
}

/// Persian months paired with their shared backend enum names — one list used
/// by onboarding, the profile editor, and any later birth-month feature.
typedef BirthMonth = ({
  String value,
  String fa,
  String en,
  String ar,
  String tr,
});

/// Every language keeps its own calendar: Persian shows the Jalali months,
/// English and Turkish the Gregorian ones, Arabic the Hijri (lunar) ones.
/// The STORED value never changes — it is the month's slot (1st..12th), so a
/// pick means «the Nth month of my own calendar» and profiles stay stable
/// across language switches.
const List<BirthMonth> kBirthMonths = [
  (
    value: 'FARVARDIN',
    fa: 'فروردین',
    en: 'January',
    ar: 'محرم',
    tr: 'Ocak',
  ),
  (
    value: 'ORDIBEHESHT',
    fa: 'اردیبهشت',
    en: 'February',
    ar: 'صفر',
    tr: 'Şubat',
  ),
  (
    value: 'KHORDAD',
    fa: 'خرداد',
    en: 'March',
    ar: 'ربيع الأول',
    tr: 'Mart',
  ),
  (
    value: 'TIR',
    fa: 'تیر',
    en: 'April',
    ar: 'ربيع الآخر',
    tr: 'Nisan',
  ),
  (
    value: 'MORDAD',
    fa: 'مرداد',
    en: 'May',
    ar: 'جمادى الأولى',
    tr: 'Mayıs',
  ),
  (
    value: 'SHAHRIVAR',
    fa: 'شهریور',
    en: 'June',
    ar: 'جمادى الآخرة',
    tr: 'Haziran',
  ),
  (
    value: 'MEHR',
    fa: 'مهر',
    en: 'July',
    ar: 'رجب',
    tr: 'Temmuz',
  ),
  (
    value: 'ABAN',
    fa: 'آبان',
    en: 'August',
    ar: 'شعبان',
    tr: 'Ağustos',
  ),
  (
    value: 'AZAR',
    fa: 'آذر',
    en: 'September',
    ar: 'رمضان',
    tr: 'Eylül',
  ),
  (
    value: 'DEY',
    fa: 'دی',
    en: 'October',
    ar: 'شوال',
    tr: 'Ekim',
  ),
  (
    value: 'BAHMAN',
    fa: 'بهمن',
    en: 'November',
    ar: 'ذو القعدة',
    tr: 'Kasım',
  ),
  (
    value: 'ESFAND',
    fa: 'اسفند',
    en: 'December',
    ar: 'ذو الحجة',
    tr: 'Aralık',
  ),
];

/// A month's label in the given language code ('fa' default).
String monthLabel(BirthMonth month, String languageCode) {
  return switch (languageCode) {
    'ar' => month.ar,
    'en' => month.en,
    'tr' => month.tr,
    _ => month.fa,
  };
}

String? birthMonthFa(String? value) {
  for (final m in kBirthMonths) {
    if (m.value == value) return m.fa;
  }
  return null;
}

/// The stored month value rendered for a locale, or null when unset/unknown.
String? birthMonthLabel(String? value, String languageCode) {
  for (final m in kBirthMonths) {
    if (m.value == value) return monthLabel(m, languageCode);
  }
  return null;
}

/// Privacy (scope §16): the name never leaves the app by default. A reading
/// that opens with «نام، …» is stripped of that greeting before sharing.
String stripLeadingName(String text, String? name) {
  final n = name?.trim();
  if (n == null || n.isEmpty) return text;
  final prefix = '$n، ';
  return text.startsWith(prefix) ? text.substring(prefix.length) : text;
}
