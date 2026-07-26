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
const List<({String value, String fa})> kBirthMonths = [
  (value: 'FARVARDIN', fa: 'فروردین'),
  (value: 'ORDIBEHESHT', fa: 'اردیبهشت'),
  (value: 'KHORDAD', fa: 'خرداد'),
  (value: 'TIR', fa: 'تیر'),
  (value: 'MORDAD', fa: 'مرداد'),
  (value: 'SHAHRIVAR', fa: 'شهریور'),
  (value: 'MEHR', fa: 'مهر'),
  (value: 'ABAN', fa: 'آبان'),
  (value: 'AZAR', fa: 'آذر'),
  (value: 'DEY', fa: 'دی'),
  (value: 'BAHMAN', fa: 'بهمن'),
  (value: 'ESFAND', fa: 'اسفند'),
];

String? birthMonthFa(String? value) {
  for (final m in kBirthMonths) {
    if (m.value == value) return m.fa;
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
