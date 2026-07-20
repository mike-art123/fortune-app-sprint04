import 'package:flutter/material.dart';

/// Hand-written localization layer with the SAME keys as `lib/l10n/*.arb`.
///
/// Why this exists: `flutter gen-l10n` output is not committed in this phase,
/// and referencing a not-yet-generated `AppLocalizations` would break the
/// build. Call sites use `context.strings.exploreTitle`, so swapping to the
/// generated class later is a one-file change with no feature churn.
///
/// Rule still holds: widgets MUST NOT hardcode user-visible strings.
class AppStrings {
  const AppStrings(this.locale);
  final Locale locale;

  static const LocalizationsDelegate<AppStrings> delegate = _AppStringsDelegate();

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ?? const AppStrings(Locale('fa'));

  bool get _fa => locale.languageCode == 'fa';

  String get appTitle => _fa ? 'فال' : 'Fortune';
  String get splashPreparing => _fa ? 'در حال آماده‌سازی…' : 'Preparing…';
  String get exploreTitle => _fa ? 'کاوش' : 'Explore';
  String get ritualTitle => _fa ? 'آیین' : 'Ritual';
  String get readingTitle => _fa ? 'فال تو' : 'Your Reading';
  String get walletTitle => _fa ? 'کیف سکه' : 'Wallet';
  String get profileTitle => _fa ? 'پروفایل' : 'Profile';
  String get placeholderNotice =>
      _fa ? 'این بخش در مرحله‌های بعد ساخته می‌شود.' : 'This section is built in later phases.';
  String get routeNotFoundTitle => _fa ? 'این صفحه پیدا نشد' : "We couldn't find that page";
  String get routeNotFoundBody => _fa
      ? 'شاید نشانی تغییر کرده باشد. می‌توانی به کاوش برگردی.'
      : 'The address may have changed. You can head back to Explore.';
  String get actionBackToExplore => _fa ? 'بازگشت به کاوش' : 'Back to Explore';
  String get actionRetry => _fa ? 'دوباره تلاش کن' : 'Try again';
  String get startupFailedTitle => _fa ? 'شروع برنامه ممکن نشد' : "The app couldn't start";
  String get exploreSubtitle => _fa ? 'یک لحظه‌ی آرام برای خودت.' : 'A quiet moment for yourself.';
  String get comingSoon => _fa ? 'به‌زودی' : 'Coming soon';
  String get comingSoonDetail =>
      _fa ? 'این آیین به‌زودی آماده می‌شود.' : 'This ritual is arriving soon.';
  String get readingSealedTitle => _fa ? 'نیتت سپرده شد.' : 'Your intention has been received.';
  String get readingSealedBody => _fa
      ? 'خوانشِ کامل در مرحله‌ی بعدِ ساخت به این‌جا می‌آید.'
      : 'The full reading arrives here in the next build stage.';
  String get actionSave => _fa ? 'ذخیره' : 'Save';
  String get actionShare => _fa ? 'اشتراک' : 'Share';
  String get readingUnavailableTitle =>
      _fa ? 'این خوانش در دسترس نیست' : 'This reading is not available';
  String get readingUnavailableBody =>
      _fa ? 'برای دیدنِ خوانش، از مسیرِ آیین وارد شو.' : 'Open a ritual to receive your reading.';
  String get startupFailedBody => _fa
      ? 'اطلاعاتت محفوظ است. یک بار دیگر امتحان کن.'
      : 'Your data is safe. Please try once more.';
  String get errorReassurance => _fa ? 'اطلاعاتت محفوظ است.' : 'Your data is safe.';
  String get savedToHistory => _fa ? 'در تاریخچه‌ات ماند.' : 'Kept in your history.';
  String get historyTitle => _fa ? 'تاریخچه' : 'History';
  String get historyEmptyTitle => _fa ? 'هنوز فالی این‌جا نیست' : 'No readings here yet';
  String get historyEmptyBody =>
      _fa ? 'اولین فال تو، آغازِ این دفتر است.' : 'Your first reading begins this journal.';
  String get historyEmptyAction => _fa ? 'گرفتن اولین فال' : 'Receive your first reading';
  String get historyLoadMore => _fa ? 'بیشتر' : 'More';
  String get walletBalanceUnit => _fa ? 'سکه' : 'coins';
  String get walletDailyRewardTitle => _fa ? 'هدیه‌ی روزانه' : 'Daily gift';
  String get walletDailyRewardBody =>
      _fa ? 'هر روز، چند سکه برای یک فالِ تازه.' : 'A few coins each day, for a fresh reading.';
  String get walletHistoryTitle => _fa ? 'تراکنش‌ها' : 'Transactions';
  String get walletHistoryEmpty => _fa ? 'هنوز تراکنشی ثبت نشده.' : 'No transactions yet.';
  String get walletKindStarter => _fa ? 'اعتبار آغازین' : 'Starter credit';
  String get walletKindDaily => _fa ? 'هدیه‌ی روزانه' : 'Daily gift';
  String get walletKindSpend => _fa ? 'گرفتن فال' : 'Reading';
  String get walletKindRefund => _fa ? 'برگشت سکه' : 'Refund';
  String get walletSubscriptionActive => _fa
      ? 'اشتراکت فعال است؛ خوانش‌ها آزادند.'
      : 'Your subscription is active — readings are covered.';
  String walletReadingCost(String cost) =>
      _fa ? 'هر خوانش $cost سکه' : 'Each reading costs $cost coins';
  String get authOutsideTelegramBody => _fa
      ? 'برای ورود، اپ را از داخل تلگرام باز کن.'
      : 'Open the app from inside Telegram to sign in.';
  String get authRejectedBody =>
      _fa ? 'ورود تأیید نشد؛ دوباره تلاش کن.' : 'Sign-in was not confirmed; try again.';
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => const ['fa', 'en'].contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}

extension AppStringsX on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}
