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
typedef BirthMonth = ({String value, String fa, String latin, String ar});

/// The Persian calendar months. Latin transliteration serves English and
/// Turkish; Arabic gets its own script. The stored value never changes.
const List<BirthMonth> kBirthMonths = [
  (value: 'FARVARDIN', fa: 'فروردین', latin: 'Farvardin', ar: 'فروردين'),
  (value: 'ORDIBEHESHT', fa: 'اردیبهشت', latin: 'Ordibehesht', ar: 'أرديبهشت'),
  (value: 'KHORDAD', fa: 'خرداد', latin: 'Khordad', ar: 'خرداد'),
  (value: 'TIR', fa: 'تیر', latin: 'Tir', ar: 'تير'),
  (value: 'MORDAD', fa: 'مرداد', latin: 'Mordad', ar: 'مرداد'),
  (value: 'SHAHRIVAR', fa: 'شهریور', latin: 'Shahrivar', ar: 'شهريور'),
  (value: 'MEHR', fa: 'مهر', latin: 'Mehr', ar: 'مهر'),
  (value: 'ABAN', fa: 'آبان', latin: 'Aban', ar: 'آبان'),
  (value: 'AZAR', fa: 'آذر', latin: 'Azar', ar: 'آذر'),
  (value: 'DEY', fa: 'دی', latin: 'Dey', ar: 'دي'),
  (value: 'BAHMAN', fa: 'بهمن', latin: 'Bahman', ar: 'بهمن'),
  (value: 'ESFAND', fa: 'اسفند', latin: 'Esfand', ar: 'إسفند'),
];

/// A month's label in the given language code ('fa' default).
String monthLabel(BirthMonth month, String languageCode) {
  return switch (languageCode) {
    'ar' => month.ar,
    'en' || 'tr' => month.latin,
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
