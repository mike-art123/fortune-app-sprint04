import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa')
  ];

  /// Application display name
  ///
  /// In fa, this message translates to:
  /// **'فال'**
  String get appTitle;

  /// Shown while the app bootstraps
  ///
  /// In fa, this message translates to:
  /// **'در حال آماده‌سازی…'**
  String get splashPreparing;

  /// Title of the Explore page
  ///
  /// In fa, this message translates to:
  /// **'کاوش'**
  String get exploreTitle;

  /// Title of the Ritual Entry page
  ///
  /// In fa, this message translates to:
  /// **'آیین'**
  String get ritualTitle;

  /// Title of the Reading result page
  ///
  /// In fa, this message translates to:
  /// **'فال تو'**
  String get readingTitle;

  /// Title of the Wallet page
  ///
  /// In fa, this message translates to:
  /// **'کیف سکه'**
  String get walletTitle;

  /// Title of the Profile page
  ///
  /// In fa, this message translates to:
  /// **'پروفایل'**
  String get profileTitle;

  /// Foundation-phase placeholder notice
  ///
  /// In fa, this message translates to:
  /// **'این بخش در مرحله‌های بعد ساخته می‌شود.'**
  String get placeholderNotice;

  /// Branded unknown-route recovery title
  ///
  /// In fa, this message translates to:
  /// **'این صفحه پیدا نشد'**
  String get routeNotFoundTitle;

  /// Unknown-route recovery description
  ///
  /// In fa, this message translates to:
  /// **'شاید نشانی تغییر کرده باشد. می‌توانی به کاوش برگردی.'**
  String get routeNotFoundBody;

  /// Recovery action label
  ///
  /// In fa, this message translates to:
  /// **'بازگشت به کاوش'**
  String get actionBackToExplore;

  /// Generic retry action
  ///
  /// In fa, this message translates to:
  /// **'دوباره تلاش کن'**
  String get actionRetry;

  /// Bootstrap failure title
  ///
  /// In fa, this message translates to:
  /// **'شروع برنامه ممکن نشد'**
  String get startupFailedTitle;

  /// Bootstrap failure reassurance
  ///
  /// In fa, this message translates to:
  /// **'اطلاعاتت محفوظ است. یک بار دیگر امتحان کن.'**
  String get startupFailedBody;

  /// No description provided for @exploreSubtitle.
  ///
  /// In fa, this message translates to:
  /// **'یک لحظه‌ی آرام برای خودت.'**
  String get exploreSubtitle;

  /// No description provided for @comingSoon.
  ///
  /// In fa, this message translates to:
  /// **'به‌زودی'**
  String get comingSoon;

  /// No description provided for @comingSoonDetail.
  ///
  /// In fa, this message translates to:
  /// **'این آیین به‌زودی آماده می‌شود.'**
  String get comingSoonDetail;

  /// No description provided for @readingSealedTitle.
  ///
  /// In fa, this message translates to:
  /// **'نیتت سپرده شد.'**
  String get readingSealedTitle;

  /// No description provided for @readingSealedBody.
  ///
  /// In fa, this message translates to:
  /// **'خوانشِ کامل در مرحله‌ی بعدِ ساخت به این‌جا می‌آید.'**
  String get readingSealedBody;

  /// No description provided for @actionSave.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره'**
  String get actionSave;

  /// No description provided for @actionShare.
  ///
  /// In fa, this message translates to:
  /// **'اشتراک'**
  String get actionShare;

  /// No description provided for @readingUnavailableTitle.
  ///
  /// In fa, this message translates to:
  /// **'این خوانش در دسترس نیست'**
  String get readingUnavailableTitle;

  /// No description provided for @readingUnavailableBody.
  ///
  /// In fa, this message translates to:
  /// **'برای دیدنِ خوانش، از مسیرِ آیین وارد شو.'**
  String get readingUnavailableBody;

  /// No description provided for @errorReassurance.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعاتت محفوظ است.'**
  String get errorReassurance;

  /// No description provided for @savedToHistory.
  ///
  /// In fa, this message translates to:
  /// **'در تاریخچه‌ات ماند.'**
  String get savedToHistory;

  /// No description provided for @historyTitle.
  ///
  /// In fa, this message translates to:
  /// **'تاریخچه'**
  String get historyTitle;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In fa, this message translates to:
  /// **'هنوز فالی این‌جا نیست'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In fa, this message translates to:
  /// **'اولین فال تو، آغازِ این دفتر است.'**
  String get historyEmptyBody;

  /// No description provided for @historyEmptyAction.
  ///
  /// In fa, this message translates to:
  /// **'گرفتن اولین فال'**
  String get historyEmptyAction;

  /// No description provided for @historyLoadMore.
  ///
  /// In fa, this message translates to:
  /// **'بیشتر'**
  String get historyLoadMore;

  /// No description provided for @walletBalanceUnit.
  ///
  /// In fa, this message translates to:
  /// **'سکه'**
  String get walletBalanceUnit;

  /// No description provided for @walletDailyRewardTitle.
  ///
  /// In fa, this message translates to:
  /// **'هدیه‌ی روزانه'**
  String get walletDailyRewardTitle;

  /// No description provided for @walletDailyRewardBody.
  ///
  /// In fa, this message translates to:
  /// **'هر روز، چند سکه برای یک فالِ تازه.'**
  String get walletDailyRewardBody;

  /// No description provided for @walletHistoryTitle.
  ///
  /// In fa, this message translates to:
  /// **'تراکنش‌ها'**
  String get walletHistoryTitle;

  /// No description provided for @walletHistoryEmpty.
  ///
  /// In fa, this message translates to:
  /// **'هنوز تراکنشی ثبت نشده.'**
  String get walletHistoryEmpty;

  /// No description provided for @walletKindStarter.
  ///
  /// In fa, this message translates to:
  /// **'اعتبار آغازین'**
  String get walletKindStarter;

  /// No description provided for @walletKindDaily.
  ///
  /// In fa, this message translates to:
  /// **'هدیه‌ی روزانه'**
  String get walletKindDaily;

  /// No description provided for @walletKindSpend.
  ///
  /// In fa, this message translates to:
  /// **'گرفتن فال'**
  String get walletKindSpend;

  /// No description provided for @walletKindRefund.
  ///
  /// In fa, this message translates to:
  /// **'برگشت سکه'**
  String get walletKindRefund;

  /// No description provided for @walletSubscriptionActive.
  ///
  /// In fa, this message translates to:
  /// **'اشتراکت فعال است؛ خوانش‌ها آزادند.'**
  String get walletSubscriptionActive;

  /// No description provided for @walletReadingCost.
  ///
  /// In fa, this message translates to:
  /// **'هر خوانش {cost} سکه'**
  String walletReadingCost(String cost);

  /// No description provided for @authOutsideTelegramBody.
  ///
  /// In fa, this message translates to:
  /// **'برای ورود، اپ را از داخل تلگرام باز کن.'**
  String get authOutsideTelegramBody;

  /// No description provided for @authRejectedBody.
  ///
  /// In fa, this message translates to:
  /// **'ورود تأیید نشد؛ دوباره تلاش کن.'**
  String get authRejectedBody;

  /// No description provided for @errorInsufficientCoins.
  ///
  /// In fa, this message translates to:
  /// **'سکه‌هایت برای این خوانش کافی نیست. اطلاعاتت محفوظ است.'**
  String get errorInsufficientCoins;

  /// No description provided for @errorSubscriptionRequired.
  ///
  /// In fa, this message translates to:
  /// **'این بخش با اشتراک باز می‌شود.'**
  String get errorSubscriptionRequired;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
