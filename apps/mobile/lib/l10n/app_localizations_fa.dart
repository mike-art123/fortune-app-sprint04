// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'فال';

  @override
  String get splashPreparing => 'در حال آماده‌سازی…';

  @override
  String get exploreTitle => 'کاوش';

  @override
  String get ritualTitle => 'آیین';

  @override
  String get readingTitle => 'فال تو';

  @override
  String get walletTitle => 'کیف سکه';

  @override
  String get profileTitle => 'پروفایل';

  @override
  String get placeholderNotice => 'این بخش در مرحله‌های بعد ساخته می‌شود.';

  @override
  String get routeNotFoundTitle => 'این صفحه پیدا نشد';

  @override
  String get routeNotFoundBody => 'شاید نشانی تغییر کرده باشد. می‌توانی به کاوش برگردی.';

  @override
  String get actionBackToExplore => 'بازگشت به کاوش';

  @override
  String get actionRetry => 'دوباره تلاش کن';

  @override
  String get startupFailedTitle => 'شروع برنامه ممکن نشد';

  @override
  String get startupFailedBody => 'اطلاعاتت محفوظ است. یک بار دیگر امتحان کن.';

  @override
  String get exploreSubtitle => 'یک لحظه‌ی آرام برای خودت.';

  @override
  String get comingSoon => 'به‌زودی';

  @override
  String get comingSoonDetail => 'این آیین به‌زودی آماده می‌شود.';

  @override
  String get readingSealedTitle => 'نیتت سپرده شد.';

  @override
  String get readingSealedBody => 'خوانشِ کامل در مرحله‌ی بعدِ ساخت به این‌جا می‌آید.';

  @override
  String get actionSave => 'ذخیره';

  @override
  String get actionShare => 'اشتراک';

  @override
  String get readingUnavailableTitle => 'این خوانش در دسترس نیست';

  @override
  String get readingUnavailableBody => 'برای دیدنِ خوانش، از مسیرِ آیین وارد شو.';

  @override
  String get errorReassurance => 'اطلاعاتت محفوظ است.';

  @override
  String get savedToHistory => 'در تاریخچه‌ات ماند.';

  @override
  String get historyTitle => 'تاریخچه';

  @override
  String get historyEmptyTitle => 'هنوز فالی این‌جا نیست';

  @override
  String get historyEmptyBody => 'اولین فال تو، آغازِ این دفتر است.';

  @override
  String get historyEmptyAction => 'گرفتن اولین فال';

  @override
  String get historyLoadMore => 'بیشتر';

  @override
  String get walletBalanceUnit => 'سکه';

  @override
  String get walletDailyRewardTitle => 'هدیه‌ی روزانه';

  @override
  String get walletDailyRewardBody => 'هر روز، چند سکه برای یک فالِ تازه.';

  @override
  String get walletHistoryTitle => 'تراکنش‌ها';

  @override
  String get walletHistoryEmpty => 'هنوز تراکنشی ثبت نشده.';

  @override
  String get walletKindStarter => 'اعتبار آغازین';

  @override
  String get walletKindDaily => 'هدیه‌ی روزانه';

  @override
  String get walletKindSpend => 'گرفتن فال';

  @override
  String get walletKindRefund => 'برگشت سکه';

  @override
  String get walletSubscriptionActive => 'اشتراکت فعال است؛ خوانش‌ها آزادند.';

  @override
  String walletReadingCost(String cost) {
    return 'هر خوانش $cost سکه';
  }

  @override
  String get authOutsideTelegramBody => 'برای ورود، اپ را از داخل تلگرام باز کن.';

  @override
  String get authRejectedBody => 'ورود تأیید نشد؛ دوباره تلاش کن.';

  @override
  String get errorInsufficientCoins => 'سکه‌هایت برای این خوانش کافی نیست. اطلاعاتت محفوظ است.';

  @override
  String get errorSubscriptionRequired => 'این بخش با اشتراک باز می‌شود.';
}
