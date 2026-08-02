import 'package:flutter/material.dart';

/// Hand-written localization layer (fa/en/ar/tr).
///
/// The base class carries the Persian voice — the product default — and each
/// language subclasses it, overriding every key. A missing override can never
/// crash: it simply falls back to Persian, which the analyzer keeps visible
/// through the class diff. Call sites use `context.strings.<key>` and never
/// hardcode user-visible text.
class AppStrings {
  const AppStrings(this.locale);
  final Locale locale;

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ??
      const AppStrings(Locale('fa'));

  /// The strings for a locale, without a BuildContext — for layers (domain,
  /// providers) that know the locale but have no widget tree.
  static AppStrings forLocale(Locale locale) {
    return switch (locale.languageCode) {
      'en' => EnStrings(locale),
      'ar' => ArStrings(locale),
      'tr' => TrStrings(locale),
      _ => AppStrings(locale),
    };
  }

  String get appTitle => 'فال';
  String get splashPreparing => 'در حال آماده‌سازی…';
  String get exploreTitle => 'کاوش';
  String get ritualTitle => 'آیین';
  String get readingTitle => 'فال تو';
  String get profileTitle => 'پروفایل';
  String get placeholderNotice => 'این بخش در مرحله‌های بعد ساخته می‌شود.';
  String get routeNotFoundTitle => 'این صفحه پیدا نشد';
  String get routeNotFoundBody =>
      'شاید نشانی تغییر کرده باشد. می‌توانی به کاوش برگردی.';
  String get actionBackToExplore => 'بازگشت به فال‌ها';
  String get actionRetry => 'دوباره تلاش کن';
  String get startupFailedTitle => 'شروع برنامه ممکن نشد';
  String get exploreSubtitle => 'یک لحظه‌ی آرام برای خودت.';
  String get comingSoon => 'به‌زودی';
  String get comingSoonDetail => 'این آیین به‌زودی آماده می‌شود.';
  String get readingSealedTitle => 'نیتت سپرده شد.';
  String get readingSealedBody =>
      'خوانشِ کامل در مرحله‌ی بعدِ ساخت به این‌جا می‌آید.';
  String get actionSave => 'ذخیره';
  String get actionShare => 'اشتراک‌گذاری';
  String get readingUnavailableTitle => 'این خوانش در دسترس نیست';
  String get readingUnavailableBody =>
      'برای دیدنِ خوانش، از مسیرِ آیین وارد شو.';
  String get startupFailedBody => 'اطلاعاتت محفوظ است. یک بار دیگر امتحان کن.';
  String get errorReassurance => 'اطلاعاتت محفوظ است.';
  String get savedToHistory => 'در تاریخچه‌ات ماند.';
  String get historyTitle => 'تاریخچه';
  String get historyEmptyTitle => 'هنوز فالی این‌جا نیست';
  String get historyEmptyBody => 'اولین فال تو، آغازِ این دفتر است.';
  String get historyEmptyAction => 'گرفتن اولین فال';
  String get historyLoadMore => 'بیشتر';
  String get intentionsTitle => 'نیت‌های من';
  String get intentionsEmptyTitle => 'هنوز نیتی نداری';
  String get intentionsEmptyBody =>
      'هر نیتی که پیش از فال زمزمه کنی این‌جا می‌ماند.';
  String get savedTitle => 'فال‌های نشان‌شده';
  String get savedEmptyTitle => 'هنوز چیزی نشان نکرده‌ای';
  String get savedEmptyBody =>
      'هر فالی را که بخواهی نگه داری، این‌جا جمع می‌شود.';
  String get savedSaveTooltip => 'ذخیره در نشان‌شده‌ها';
  String get savedRemoveTooltip => 'برداشتن از نشان‌شده‌ها';
  String get savedToast => 'در نشان‌شده‌ها ذخیره شد';
  String get savedError => 'ذخیره نشد؛ دوباره تلاش کن';
  String get historyClearTooltip => 'پاک‌کردن تاریخچه';
  String get coffeeCaptureHint =>
      'فنجان را وارونه کن، بگذار ته‌نشین شود، بعد از تهِ فنجان یک عکس بگیر.';
  String get coffeeTakePhoto => 'گرفتن عکس';
  String get coffeeFromGallery => 'انتخاب از گالری';
  String get coffeeRetake => 'عکس دیگر';
  String get coffeeGuideTitle => 'راهنمای نشانه‌ها';
  String get coffeeGuideIntro =>
      'اگر خواستی خودت هم فنجان را بخوانی، این نشانه‌ها راهنمایت می‌کنند.';
  String get historyClearTitle => 'همهٔ تاریخچه پاک شود؟';
  String get historyClearBody =>
      'همهٔ خوانش‌های گذشته‌ات برای همیشه پاک می‌شوند و بازگشتی ندارد.';
  String get historyClearConfirm => 'پاک کن';
  String get historyDeleteTooltip => 'پاک‌کردن این خوانش';
  String get historyDeleteTitle => 'این خوانش پاک شود؟';
  String get historyDeleteBody => 'این خوانش برای همیشه پاک می‌شود.';
  String get historyDeleteConfirm => 'پاک کن';
  String get actionCancel => 'انصراف';
  String get authOutsideTelegramBody =>
      'برای ورود، اپ را از داخل تلگرام باز کن.';
  String get authRejectedBody => 'ورود تأیید نشد؛ دوباره تلاش کن.';
  String get navProfile => 'پروفایل';
  String get navFortunes => 'فال‌ها';
  String get navHome => 'خانه';
  String get navHistory => 'تاریخچه';
  String get navTerms => 'قوانین';
  String get settingsTitle => 'تنظیمات';
  String get actionBack => 'بازگشت';
  String get personalizeTitle => 'بخت‌نگار تو را چه صدا کند؟';
  String get personalizeNameHint => 'نامت، یا نامی که دوستش داری';
  String get personalizeMonthQuestion => 'ماه تولدت؟';
  String get personalizeNote =>
      'اطلاعاتی که وارد می‌کنی، فالت را دقیق‌تر و شخصی‌تر می‌کند.';
  String get personalizeGo => 'بریم';
  String get personalizeSaving => 'در حال ذخیره…';
  String get personalizeSkip => 'نمی‌خوام ثبت کنم';
  String get homeSeeAll => 'مشاهده همه';
  String get searchFortunesHint => 'جست‌وجوی فال';
  String get homeGuestName => 'مسافرِ بخت';
  String get fortuneSoonToast => 'این فال به‌زودی فعال می‌شود';
  String get accessSheetTitle => 'روش دریافت فال را انتخاب کنید';
  String get accessAdOptionTitle => 'دریافت رایگان با تبلیغ';
  String get accessAdOptionBody =>
      'یک تبلیغ کوتاه ببینید و فال خود را رایگان دریافت کنید.';
  String get accessAdButton => 'دیدن تبلیغ و گرفتن فال';
  String get accessLimitTitle => 'سهمیه فال رایگان امروز تمام شده است';
  String get accessLimitBody =>
      'فردا دوباره سر بزنید تا فال‌های تازه را رایگان دریافت کنید.';
  String get actionOkay => 'باشه';
  String get accessNoAdTitle => 'در حال حاضر تبلیغی در دسترس نیست';
  String get accessNoAdBody => 'کمی بعد دوباره امتحان کنید.';
  String get accessRetryLabel => 'تلاش دوباره';
  String get shareBrandLine => '🔮 بخت‌نگار';
  String get shareCopied => 'متنِ فال کپی شد؛ هرجا خواستی بفرست.';
  String get shareFailed => 'اشتراک‌گذاری ممکن نشد؛ دوباره تلاش کن.';
  String get profileSoonToast => 'این بخش به‌زودی فعال می‌شود';
  String get profileHistory => 'تاریخچهٔ فال‌ها';
  String get profileSupportAbout => 'پشتیبانی و درباره ما';
  String get profileSeeker => 'جست‌وجوگرِ حقیقت';
  String get profileEditTooltip => 'ویرایش نام و ماه تولد';
  String get profileRecsTitle => 'پیشنهاد بر پایهٔ فال‌های خودم';
  String get profileRecsBody => 'خاموش که باشد، هیچ پیشنهادی ساخته نمی‌شود.';
  String get inviteShareText => 'با بخت‌نگار هر روز فال و استخاره بگیر ✨';
  String get inviteTitle => 'دعوت از دوستان';
  String get inviteBody => 'بخت‌نگار را با دوستانت به اشتراک بگذار';
  String get socialTelegram => 'کانال تلگرام';
  String get socialInstagram => 'اینستاگرام';
  String profileSeekerBorn(String month) => 'متولدِ $month · جست‌وجوگرِ حقیقت';
  String profileBorn(String month) => 'متولدِ $month';
  String get nextStripTitle => 'بعد از این';
  String get reasonFamily => 'هم‌خانوادهٔ چیزی که همین حالا خواندی';
  String get reasonUntried => 'هنوز امتحانش نکرده‌ای';
  String get reasonAgain => 'قبلاً خوانده‌ای؛ شاید دوباره';
  String get dayPartMornings => 'صبح‌ها';
  String get dayPartNoons => 'ظهرها';
  String get dayPartEvenings => 'عصرها';
  String get dayPartNights => 'شب‌ها';
  String get onboardingNameQuestion =>
      'دوست داری بخت‌نگار تو را با چه نامی صدا کند؟';
  String get onboardingMonthQuestion => 'ماه تولدت کدام است؟';
  String get onboardingPersonalNote =>
      'از این پس فال‌هایت کمی شخصی‌تر خواهند بود.';
  String get actionContinue => 'ادامه';
  String reasonHabit(String when) => '$when بیشتر همین را می‌خوانی';
  String onboardingWelcome(String name) => 'خوش آمدی، $name.';
  String get failureNetwork =>
      'ارتباط برقرار نشد. اتصالت را بررسی کن و دوباره تلاش کن.';
  String get failureTimeout => 'کمی طول کشید. دوباره تلاش کن.';
  String get failureAuth => 'برای ادامه باید دوباره وارد شوی.';
  String get failureNotFound => 'چیزی که دنبالش بودی پیدا نشد.';
  String get failureValidation => 'ورودی کامل نیست؛ یک بار دیگر نگاهش کن.';
  String get failureConflict => 'این درخواست قبلاً ثبت شده است.';
  String get failureRateLimited => 'کمی صبر کن و دوباره تلاش کن.';
  String get failureCoins =>
      'سکه‌هایت برای این خوانش کافی نیست. اطلاعاتت محفوظ است.';
  String get failureSubscription => 'این بخش با اشتراک باز می‌شود.';
  String get failureStorage => 'ذخیره‌سازی ممکن نشد.';
  String get failureUnknown =>
      'مشکلی پیش آمد. اطلاعاتت محفوظ است؛ دوباره تلاش کن.';
  String get searchHintFull => 'دنبال چه فالی می‌گردی؟';
  String get voiceListening => 'دارم گوش می‌دهم…';
  String get voiceMicDenied =>
      'اجازهٔ میکروفون داده نشد؛ از تنظیمات مرورگر روشنش کن.';
  String get voiceNothingHeard => 'چیزی نشنیدم؛ دوباره بگو یا بنویس.';
  String get voiceUnsupported => 'مرورگرت شنیدن را پشتیبانی نمی‌کند.';
  String get voiceFailed => 'الان نشد؛ یک‌بار دیگر امتحان کن.';
  String get voiceStopTooltip => 'توقف';
  String get voiceSearchTooltip => 'جست‌وجوی صوتی';
  String get clearTooltip => 'پاک کردن';
  String get searchNoMatch =>
      'با این نام چیزی پیدا نشد؛ از فهرست پایین انتخاب کن.';
  String get searchAsking => 'دارم می‌پرسم…';
  String get searchAskAssistant => 'از دستیار بپرس';
  String get adPreparing => 'در حال آماده‌سازی تبلیغ...';

  /// App Review Guideline 5.1.2(i): the person is told what leaves the device
  /// at the moment they choose to send it, not in a policy they would have to
  /// go looking for. Tapping the line opens that policy anyway.
  String get aiConsentNote =>
      'با زدن این دکمه می‌پذیری که نیتت — و در فال قهوه، عکس فنجانت — برای '
      'نوشتنِ تفسیر به یک سرویسِ هوش مصنوعیِ شخصِ ثالث فرستاده شود. '
      'برای جزئیات، این‌جا را بزن و حریم خصوصی را بخوان.';
  String get splashTagline => 'در حال گشودن رازهای بخت شما…';
  String get editProfileTitle => 'نام و ماه تولد';
  String get audioCardTitle => 'صدای پس‌زمینه';
  String get audioCardSubtitle => 'آرام و بی‌مزاحمت؛ هر وقت خواستی خاموشش کن.';
  String get historyLookback => 'نگاهی به گذشته';
  String get historyCounting => 'در حال شمردن…';
  String get historyAiNote =>
      'این جمله را دستیار از شمارشِ خودِ فال‌هایت نوشته است.';
  String get notifTitle => 'یادآوری‌ها';
  String get notifMutedNote => 'تا وقتی خودت بخواهی، پیامی نمی‌فرستیم.';
  String get notifDaily => 'فال امروز';
  String get notifStreak => 'وقتی چند روز سر نزدم';
  String get notifWeekly => 'نگاهی به هفته‌ای که گذشت';
  String get notifUnmute => 'باز هم خبرم بده';
  String get notifMuteWeek => 'یک هفته چیزی نفرست';
  String get reflectTitle => 'برای خودت بنویس';
  String get reflectHint => 'هرچه دوست داری…';
  String get reflectSave => 'ثبت';
  String get reflectSaved => 'ثبت شد';
  String get reflectPrivacy =>
      'این یادداشت خصوصی است: جایی به اشتراک گذاشته نمی‌شود و از آن'
      ' پیشنهادی ساخته نمی‌شود.';
  String notifQuiet(String from, String to) =>
      'بین $from و $to هیچ پیامی نمی‌آید.';
  String get legalTerms => 'قوانین';
  String get legalPrivacy => 'حریم خصوصی';
  String get legalAbout => 'درباره';
  String get legalContact => 'تماس';
  String get aboutTitle => 'درباره بخت‌نگار';
  String get contactTitle => 'تماس با ما';
  String get privacyUpdated => 'آخرین به‌روزرسانی: تیر ۱۴۰۵ (July 2026)';
  String get legalUnderstood => 'متوجه شدم';
  String get contactChannel => 'کانال تلگرام';
  String get contactBot => 'بات بخت‌نگار';
  String get contactEmailTile => 'ایمیل پشتیبانی (لمس کن تا کپی شود)';
  String get contactVersionTile => 'نسخهٔ برنامه';
  String get contactReport => 'گزارش مشکل';
  String get contactReportEmailSubject => 'گزارش مشکل بخت‌نگار';
  String get contactEmailCopied => 'ایمیل کپی شد.';
  String get termsHero => 'بخت‌نگار هیچ‌گونه مسئولیتی نمی‌پذیرد.\n'
      'این برنامه فقط یک فال است، و تصمیم‌گیرندهٔ تمام امورِ '
      'زندگی‌تان خودتان هستید.';
  String get aboutHero => 'بخت‌نگار — فال و اسرارِ زندگی.\n'
      'یک لحظهٔ آرام برای خودت، به زبان فارسی.';
  String get privacyHero => 'حریم خصوصی تو برای ما جدی است.\n'
      'کمترین دادهٔ ممکن، فقط برای کارکردن خودِ فال.';
  String get contactHero => 'سؤال، پیشنهاد یا مشکلی داری؟\n'
      'همین‌جا در کنارت هستیم.';
  String get disclaimerBody =>
      'فال‌های بخت‌نگار صرفاً برای سرگرمی و تأمل شخصی ارائه '
      'می‌شوند و نباید مبنای تصمیم‌های مهم زندگی قرار گیرند.';
  String versionLine(String v) => 'نسخهٔ $v';
  String legalCopyright(String year) =>
      '© بخت‌نگار $year — همهٔ حقوق محفوظ است.';
  String get badgeSpecial => 'ویژه';
}

/// English.
class EnStrings extends AppStrings {
  const EnStrings(super.locale);

  @override
  String get appTitle => 'Fortune';
  @override
  String get splashPreparing => 'Preparing…';
  @override
  String get exploreTitle => 'Explore';
  @override
  String get ritualTitle => 'Ritual';
  @override
  String get readingTitle => 'Your Reading';
  @override
  String get profileTitle => 'Profile';
  @override
  String get placeholderNotice => 'This section is built in later phases.';
  @override
  String get routeNotFoundTitle => "We couldn't find that page";
  @override
  String get routeNotFoundBody =>
      'The address may have changed. You can head back to Explore.';
  @override
  String get actionBackToExplore => 'Back to Fortunes';
  @override
  String get actionRetry => 'Try again';
  @override
  String get startupFailedTitle => "The app couldn't start";
  @override
  String get exploreSubtitle => 'A quiet moment for yourself.';
  @override
  String get comingSoon => 'Coming soon';
  @override
  String get comingSoonDetail => 'This ritual is arriving soon.';
  @override
  String get readingSealedTitle => 'Your intention has been received.';
  @override
  String get readingSealedBody =>
      'The full reading arrives here in the next build stage.';
  @override
  String get actionSave => 'Save';
  @override
  String get actionShare => 'Share';
  @override
  String get readingUnavailableTitle => 'This reading is not available';
  @override
  String get readingUnavailableBody => 'Open a ritual to receive your reading.';
  @override
  String get startupFailedBody => 'Your data is safe. Please try once more.';
  @override
  String get errorReassurance => 'Your data is safe.';
  @override
  String get savedToHistory => 'Kept in your history.';
  @override
  String get historyTitle => 'History';
  @override
  String get historyEmptyTitle => 'No readings here yet';
  @override
  String get historyEmptyBody => 'Your first reading begins this journal.';
  @override
  String get historyEmptyAction => 'Receive your first reading';
  @override
  String get historyLoadMore => 'More';
  @override
  String get intentionsTitle => 'My intentions';
  @override
  String get intentionsEmptyTitle => 'No intentions yet';
  @override
  String get intentionsEmptyBody =>
      'Every intention you whisper before a fortune is kept here.';
  @override
  String get savedTitle => 'Saved fortunes';
  @override
  String get savedEmptyTitle => 'Nothing saved yet';
  @override
  String get savedEmptyBody => 'Every fortune you keep is gathered here.';
  @override
  String get savedSaveTooltip => 'Save';
  @override
  String get savedRemoveTooltip => 'Remove from saved';
  @override
  String get savedToast => 'Saved';
  @override
  String get savedError => 'Could not save';
  @override
  String get historyClearTooltip => 'Clear history';
  @override
  String get coffeeCaptureHint =>
      'Flip the cup, let it settle, then photograph the bottom.';
  @override
  String get coffeeTakePhoto => 'Take a photo';
  @override
  String get coffeeFromGallery => 'Choose from gallery';
  @override
  String get coffeeRetake => 'Retake';
  @override
  String get coffeeGuideTitle => 'Symbol guide';
  @override
  String get coffeeGuideIntro => 'Read it yourself with these symbols.';
  @override
  String get historyClearTitle => 'Clear all history?';
  @override
  String get historyClearBody => 'This permanently deletes your whole history.';
  @override
  String get historyClearConfirm => 'Clear';
  @override
  String get historyDeleteTooltip => 'Delete this reading';
  @override
  String get historyDeleteTitle => 'Delete this reading?';
  @override
  String get historyDeleteBody => 'This reading will be permanently deleted.';
  @override
  String get historyDeleteConfirm => 'Delete';
  @override
  String get actionCancel => 'Cancel';
  @override
  String get authOutsideTelegramBody =>
      'Open the app from inside Telegram to sign in.';
  @override
  String get authRejectedBody => 'Sign-in was not confirmed; try again.';
  @override
  String get navProfile => 'Profile';
  @override
  String get navFortunes => 'Fortunes';
  @override
  String get navHome => 'Home';
  @override
  String get navHistory => 'History';
  @override
  String get navTerms => 'Terms';
  @override
  String get settingsTitle => 'Settings';
  @override
  String get actionBack => 'Back';
  @override
  String get personalizeTitle => 'What should BakhtNegar call you?';
  @override
  String get personalizeNameHint => 'Your name, or one you love';
  @override
  String get personalizeMonthQuestion => 'Your birth month?';
  @override
  String get personalizeNote =>
      'What you share makes your reading more precise and personal.';
  @override
  String get personalizeGo => 'Let\'s go';
  @override
  String get personalizeSaving => 'Saving…';
  @override
  String get personalizeSkip => 'I\'d rather not';
  @override
  String get homeSeeAll => 'See all';
  @override
  String get searchFortunesHint => 'Search fortunes';
  @override
  String get homeGuestName => 'Fortune traveller';
  @override
  String get fortuneSoonToast => 'This fortune arrives soon';
  @override
  String get accessSheetTitle => 'Choose how to receive your fortune';
  @override
  String get accessAdOptionTitle => 'Free with an ad';
  @override
  String get accessAdOptionBody =>
      'Watch a short ad and receive your fortune free.';
  @override
  String get accessAdButton => 'Watch the ad, get the reading';
  @override
  String get accessLimitTitle => 'Today\'s free readings are used up';
  @override
  String get accessLimitBody => 'Come back tomorrow for fresh free readings.';
  @override
  String get actionOkay => 'Okay';
  @override
  String get accessNoAdTitle => 'No ad is available right now';
  @override
  String get accessNoAdBody => 'Try again in a little while.';
  @override
  String get accessRetryLabel => 'Try again';
  @override
  String get shareBrandLine => '🔮 BakhtNegar';
  @override
  String get shareCopied => 'The reading was copied; share it anywhere.';
  @override
  String get shareFailed => 'Sharing did not work; try again.';
  @override
  String get profileSoonToast => 'This section arrives soon';
  @override
  String get profileHistory => 'Reading history';
  @override
  String get profileSupportAbout => 'Support and about';
  @override
  String get profileSeeker => 'Seeker of truth';
  @override
  String get profileEditTooltip => 'Edit name and birth month';
  @override
  String get profileRecsTitle => 'Suggestions from my own readings';
  @override
  String get profileRecsBody => 'When off, no suggestions are made.';
  @override
  String get inviteShareText =>
      'Daily fortunes and istikhara with BakhtNegar ✨';
  @override
  String get inviteTitle => 'Invite friends';
  @override
  String get inviteBody => 'Share BakhtNegar with your friends';
  @override
  String get socialTelegram => 'Telegram channel';
  @override
  String get socialInstagram => 'Instagram';
  @override
  String profileSeekerBorn(String month) => 'Born in $month · Seeker of truth';
  @override
  String profileBorn(String month) => 'Born in $month';
  @override
  String get nextStripTitle => 'After this';
  @override
  String get reasonFamily => 'Kin to what you just read';
  @override
  String get reasonUntried => 'You have not tried it yet';
  @override
  String get reasonAgain => 'Read before; perhaps again';
  @override
  String get dayPartMornings => 'in the mornings';
  @override
  String get dayPartNoons => 'around noon';
  @override
  String get dayPartEvenings => 'in the evenings';
  @override
  String get dayPartNights => 'at night';
  @override
  String get onboardingNameQuestion =>
      'What name would you like BakhtNegar to call you?';
  @override
  String get onboardingMonthQuestion => 'Which is your birth month?';
  @override
  String get onboardingPersonalNote =>
      'From now on your readings will be a little more personal.';
  @override
  String get actionContinue => 'Continue';
  @override
  String reasonHabit(String when) => 'You mostly read this $when';
  @override
  String onboardingWelcome(String name) => 'Welcome, $name.';
  @override
  String get failureNetwork =>
      'Couldn\'t connect. Check your connection and try again.';
  @override
  String get failureTimeout => 'That took a bit long. Try again.';
  @override
  String get failureAuth => 'Please sign in again to continue.';
  @override
  String get failureNotFound => 'What you were looking for wasn\'t found.';
  @override
  String get failureValidation =>
      'The input isn\'t complete; take another look.';
  @override
  String get failureConflict => 'This request was already submitted.';
  @override
  String get failureRateLimited => 'Wait a moment, then try again.';
  @override
  String get failureCoins =>
      'Not enough coins for this reading. Your data is safe.';
  @override
  String get failureSubscription => 'This area opens with a subscription.';
  @override
  String get failureStorage => 'Saving didn\'t work.';
  @override
  String get failureUnknown =>
      'Something went wrong. Your data is safe — try again.';
  @override
  String get searchHintFull => 'What fortune are you looking for?';
  @override
  String get voiceListening => 'Listening…';
  @override
  String get voiceMicDenied =>
      'Microphone permission was denied; enable it in your browser settings.';
  @override
  String get voiceNothingHeard =>
      'I didn\'t catch that; say it again or type it.';
  @override
  String get voiceUnsupported => 'Your browser doesn\'t support voice input.';
  @override
  String get voiceFailed => 'That didn\'t work; give it another try.';
  @override
  String get voiceStopTooltip => 'Stop';
  @override
  String get voiceSearchTooltip => 'Voice search';
  @override
  String get clearTooltip => 'Clear';
  @override
  String get searchNoMatch =>
      'Nothing matched that name; pick from the list below.';
  @override
  String get searchAsking => 'Asking…';
  @override
  String get searchAskAssistant => 'Ask the assistant';
  @override
  String get adPreparing => 'Preparing the ad...';

  @override
  String get aiConsentNote =>
      'By tapping this you agree that your intention — and, for the coffee '
      'reading, the photo of your cup — is sent to a third-party AI service '
      'to write the interpretation. Tap here to read the privacy policy.';
  @override
  String get splashTagline => 'Unveiling the secrets of your fortune…';
  @override
  String get editProfileTitle => 'Name and birth month';
  @override
  String get audioCardTitle => 'Ambient sound';
  @override
  String get audioCardSubtitle =>
      'Soft and unobtrusive; turn it off whenever you like.';
  @override
  String get historyLookback => 'A look back';
  @override
  String get historyCounting => 'Counting…';
  @override
  String get historyAiNote =>
      'The assistant wrote this line from the count of your own readings.';
  @override
  String get notifTitle => 'Reminders';
  @override
  String get notifMutedNote => 'Until you say so, we send nothing.';
  @override
  String get notifDaily => 'Today\'s fortune';
  @override
  String get notifStreak => 'When I\'m away for a few days';
  @override
  String get notifWeekly => 'A look at the week gone by';
  @override
  String get notifUnmute => 'Tell me again';
  @override
  String get notifMuteWeek => 'Nothing for a week';
  @override
  String get reflectTitle => 'Write for yourself';
  @override
  String get reflectHint => 'Whatever you like…';
  @override
  String get reflectSave => 'Note it';
  @override
  String get reflectSaved => 'Noted';
  @override
  String get reflectPrivacy =>
      'This note is private — never shared, never turned into suggestions.';
  @override
  String notifQuiet(String from, String to) =>
      'No messages between $from and $to.';
  @override
  String get legalTerms => 'Terms';
  @override
  String get legalPrivacy => 'Privacy';
  @override
  String get legalAbout => 'About';
  @override
  String get legalContact => 'Contact';
  @override
  String get aboutTitle => 'About BakhtNegar';
  @override
  String get contactTitle => 'Contact us';
  @override
  String get privacyUpdated => 'Last updated: July 2026';
  @override
  String get legalUnderstood => 'Understood';
  @override
  String get contactChannel => 'Telegram channel';
  @override
  String get contactBot => 'BakhtNegar bot';
  @override
  String get contactEmailTile => 'Support email (tap to copy)';
  @override
  String get contactVersionTile => 'App version';
  @override
  String get contactReport => 'Report a problem';
  @override
  String get contactReportEmailSubject => 'BakhtNegar problem report';
  @override
  String get contactEmailCopied => 'Email copied.';
  @override
  String get termsHero =>
      'BakhtNegar accepts no responsibility.\nEvery decision is yours.';
  @override
  String get aboutHero =>
      'BakhtNegar — fortunes and secrets of life.\nA calm moment of your own.';
  @override
  String get privacyHero =>
      'Your privacy is serious to us.\nThe least data, only for the fortune.';
  @override
  String get contactHero =>
      'A question, an idea, a problem?\nWe are right here with you.';
  @override
  String get disclaimerBody =>
      'BakhtNegar readings are offered for entertainment and personal '
      'reflection only, never as a basis for important life decisions.';
  @override
  String versionLine(String v) => 'Version $v';
  @override
  String legalCopyright(String year) =>
      '© BakhtNegar $year — all rights reserved.';
  @override
  String get badgeSpecial => 'Special';
}

/// Arabic — modern, calm فصحى; RTL like Persian.
class ArStrings extends AppStrings {
  const ArStrings(super.locale);

  @override
  String get appTitle => 'فأل';
  @override
  String get splashPreparing => 'جارٍ التحضير…';
  @override
  String get exploreTitle => 'استكشاف';
  @override
  String get ritualTitle => 'الطقس';
  @override
  String get readingTitle => 'قراءتك';
  @override
  String get profileTitle => 'الملف الشخصي';
  @override
  String get placeholderNotice => 'يُبنى هذا القسم في مراحل لاحقة.';
  @override
  String get routeNotFoundTitle => 'لم نعثر على هذه الصفحة';
  @override
  String get routeNotFoundBody =>
      'ربما تغيّر العنوان. يمكنك العودة إلى الاستكشاف.';
  @override
  String get actionBackToExplore => 'العودة إلى الفؤول';
  @override
  String get actionRetry => 'حاول مرة أخرى';
  @override
  String get startupFailedTitle => 'تعذّر بدء التطبيق';
  @override
  String get exploreSubtitle => 'لحظة هادئة لنفسك.';
  @override
  String get comingSoon => 'قريبًا';
  @override
  String get comingSoonDetail => 'هذا الطقس يصل قريبًا.';
  @override
  String get readingSealedTitle => 'وصلت نيّتك.';
  @override
  String get readingSealedBody => 'تصل القراءة الكاملة هنا في المرحلة القادمة.';
  @override
  String get actionSave => 'حفظ';
  @override
  String get actionShare => 'مشاركة';
  @override
  String get readingUnavailableTitle => 'هذه القراءة غير متاحة';
  @override
  String get readingUnavailableBody => 'ادخل من مسار الطقس لتصلك قراءتك.';
  @override
  String get startupFailedBody => 'بياناتك محفوظة. جرّب مرة أخرى.';
  @override
  String get errorReassurance => 'بياناتك محفوظة.';
  @override
  String get savedToHistory => 'حُفظت في سجلّك.';
  @override
  String get historyTitle => 'السجلّ';
  @override
  String get historyEmptyTitle => 'لا قراءات هنا بعد';
  @override
  String get historyEmptyBody => 'قراءتك الأولى تفتتح هذا الدفتر.';
  @override
  String get historyEmptyAction => 'احصل على قراءتك الأولى';
  @override
  String get historyLoadMore => 'المزيد';
  @override
  String get intentionsTitle => 'نيّاتي';
  @override
  String get intentionsEmptyTitle => 'لا نيّات بعد';
  @override
  String get intentionsEmptyBody => 'كل نيّة تهمس بها قبل الفأل تبقى هنا.';
  @override
  String get savedTitle => 'الفؤول المحفوظة';
  @override
  String get savedEmptyTitle => 'لم تحفظ شيئًا بعد';
  @override
  String get savedEmptyBody => 'كل فأل تريد الاحتفاظ به يُجمع هنا.';
  @override
  String get savedSaveTooltip => 'حفظ';
  @override
  String get savedRemoveTooltip => 'إزالة من المحفوظات';
  @override
  String get savedToast => 'تم الحفظ';
  @override
  String get savedError => 'تعذّر الحفظ؛ حاول مرة أخرى';
  @override
  String get historyClearTooltip => 'مسح السجلّ';
  @override
  String get coffeeCaptureHint =>
      'اقلب الفنجان، ودعه يستقرّ، ثم التقط صورة لقاعه.';
  @override
  String get coffeeTakePhoto => 'التقاط صورة';
  @override
  String get coffeeFromGallery => 'اختيار من المعرض';
  @override
  String get coffeeRetake => 'صورة أخرى';
  @override
  String get coffeeGuideTitle => 'دليل الرموز';
  @override
  String get coffeeGuideIntro =>
      'إن أردت قراءة الفنجان بنفسك، فهذه الرموز ترشدك.';
  @override
  String get historyClearTitle => 'هل يُمسح السجلّ كله؟';
  @override
  String get historyClearBody =>
      'تُمسح كل قراءاتك السابقة نهائيًا ولا رجوع عنها.';
  @override
  String get historyClearConfirm => 'امسح';
  @override
  String get historyDeleteTooltip => 'حذف هذه القراءة';
  @override
  String get historyDeleteTitle => 'هل تُحذف هذه القراءة؟';
  @override
  String get historyDeleteBody => 'تُحذف هذه القراءة نهائيًا.';
  @override
  String get historyDeleteConfirm => 'احذف';
  @override
  String get actionCancel => 'إلغاء';
  @override
  String get authOutsideTelegramBody =>
      'للدخول، افتح التطبيق من داخل تيليجرام.';
  @override
  String get authRejectedBody => 'لم يتأكد الدخول؛ حاول مرة أخرى.';
  @override
  String get navProfile => 'الملف الشخصي';
  @override
  String get navFortunes => 'الفؤول';
  @override
  String get navHome => 'الرئيسية';
  @override
  String get navHistory => 'السجلّ';
  @override
  String get navTerms => 'الشروط';
  @override
  String get settingsTitle => 'الإعدادات';
  @override
  String get actionBack => 'رجوع';
  @override
  String get personalizeTitle => 'بمَ يناديك بخت‌نگار؟';
  @override
  String get personalizeNameHint => 'اسمك، أو اسم تحبّه';
  @override
  String get personalizeMonthQuestion => 'شهر ميلادك؟';
  @override
  String get personalizeNote => 'ما تدخله يجعل فألك أدقّ وأكثر خصوصية.';
  @override
  String get personalizeGo => 'هيّا بنا';
  @override
  String get personalizeSaving => 'جارٍ الحفظ…';
  @override
  String get personalizeSkip => 'لا أريد التسجيل';
  @override
  String get homeSeeAll => 'عرض الكل';
  @override
  String get searchFortunesHint => 'ابحث عن فأل';
  @override
  String get homeGuestName => 'مسافر البخت';
  @override
  String get fortuneSoonToast => 'يتاح هذا الفأل قريبًا';
  @override
  String get accessSheetTitle => 'اختر طريقة الحصول على فألك';
  @override
  String get accessAdOptionTitle => 'مجانًا بمشاهدة إعلان';
  @override
  String get accessAdOptionBody => 'شاهد إعلانًا قصيرًا واحصل على فألك مجانًا.';
  @override
  String get accessAdButton => 'شاهد الإعلان وخذ فألك';
  @override
  String get accessLimitTitle => 'انتهت حصة اليوم من الفؤول المجانية';
  @override
  String get accessLimitBody => 'عُد غدًا لتحصل على فؤول جديدة مجانًا.';
  @override
  String get actionOkay => 'حسنًا';
  @override
  String get accessNoAdTitle => 'لا يوجد إعلان متاح الآن';
  @override
  String get accessNoAdBody => 'حاول مرة أخرى بعد قليل.';
  @override
  String get accessRetryLabel => 'حاول مجددًا';
  @override
  String get shareBrandLine => '🔮 بخت‌نگار';
  @override
  String get shareCopied => 'نُسخ نصّ الفأل؛ أرسله أينما شئت.';
  @override
  String get shareFailed => 'تعذّرت المشاركة؛ حاول مرة أخرى.';
  @override
  String get profileSoonToast => 'يتاح هذا القسم قريبًا';
  @override
  String get profileHistory => 'سجلّ الفؤول';
  @override
  String get profileSupportAbout => 'الدعم وعنّا';
  @override
  String get profileSeeker => 'باحث عن الحقيقة';
  @override
  String get profileEditTooltip => 'تعديل الاسم وشهر الميلاد';
  @override
  String get profileRecsTitle => 'اقتراحات من فؤولي';
  @override
  String get profileRecsBody => 'عند إيقافه لا تُبنى أي اقتراحات.';
  @override
  String get inviteShareText => 'مع بخت‌نگار خذ فألك واستخارتك كل يوم ✨';
  @override
  String get inviteTitle => 'ادعُ أصدقاءك';
  @override
  String get inviteBody => 'شارك بخت‌نگار مع أصدقائك';
  @override
  String get socialTelegram => 'قناة تيليجرام';
  @override
  String get socialInstagram => 'إنستغرام';
  @override
  String profileSeekerBorn(String month) =>
      'من مواليد $month · باحث عن الحقيقة';
  @override
  String profileBorn(String month) => 'من مواليد $month';
  @override
  String get nextStripTitle => 'بعد هذا';
  @override
  String get reasonFamily => 'من عائلة ما قرأته للتوّ';
  @override
  String get reasonUntried => 'لم تجرّبه بعد';
  @override
  String get reasonAgain => 'قرأته من قبل؛ ربما مجددًا';
  @override
  String get dayPartMornings => 'في الصباح';
  @override
  String get dayPartNoons => 'عند الظهيرة';
  @override
  String get dayPartEvenings => 'في المساء';
  @override
  String get dayPartNights => 'في الليل';
  @override
  String get onboardingNameQuestion => 'بأي اسم تحب أن يناديك بخت‌نگار؟';
  @override
  String get onboardingMonthQuestion => 'ما شهر ميلادك؟';
  @override
  String get onboardingPersonalNote =>
      'من الآن ستكون فؤولك أكثر خصوصية قليلًا.';
  @override
  String get actionContinue => 'متابعة';
  @override
  String reasonHabit(String when) => 'غالبًا تقرأ هذا $when';
  @override
  String onboardingWelcome(String name) => 'أهلًا بك يا $name.';
  @override
  String get failureNetwork => 'تعذّر الاتصال. تحقّق من اتصالك وحاول مجددًا.';
  @override
  String get failureTimeout => 'استغرق الأمر وقتًا طويلًا. حاول مجددًا.';
  @override
  String get failureAuth => 'سجّل الدخول مجددًا للمتابعة.';
  @override
  String get failureNotFound => 'لم نعثر على ما كنت تبحث عنه.';
  @override
  String get failureValidation => 'المدخلات غير مكتملة؛ ألقِ نظرة أخرى.';
  @override
  String get failureConflict => 'سبق تسجيل هذا الطلب.';
  @override
  String get failureRateLimited => 'انتظر قليلًا ثم حاول مجددًا.';
  @override
  String get failureCoins => 'عملاتك لا تكفي لهذه القراءة. بياناتك محفوظة.';
  @override
  String get failureSubscription => 'يفتح هذا القسم بالاشتراك.';
  @override
  String get failureStorage => 'تعذّر الحفظ.';
  @override
  String get failureUnknown => 'حدث خطأ ما. بياناتك محفوظة؛ حاول مجددًا.';
  @override
  String get searchHintFull => 'عن أي فأل تبحث؟';
  @override
  String get voiceListening => 'أستمع إليك…';
  @override
  String get voiceMicDenied =>
      'لم يُسمح باستخدام الميكروفون؛ فعّله من إعدادات المتصفح.';
  @override
  String get voiceNothingHeard => 'لم أسمع شيئًا؛ قلها مجددًا أو اكتبها.';
  @override
  String get voiceUnsupported => 'متصفحك لا يدعم الإدخال الصوتي.';
  @override
  String get voiceFailed => 'لم ينجح الأمر الآن؛ جرّب مرة أخرى.';
  @override
  String get voiceStopTooltip => 'إيقاف';
  @override
  String get voiceSearchTooltip => 'بحث صوتي';
  @override
  String get clearTooltip => 'مسح';
  @override
  String get searchNoMatch => 'لم نجد شيئًا بهذا الاسم؛ اختر من القائمة أدناه.';
  @override
  String get searchAsking => 'أسأل الآن…';
  @override
  String get searchAskAssistant => 'اسأل المساعد';
  @override
  String get adPreparing => 'جارٍ تجهيز الإعلان...';

  @override
  String get aiConsentNote =>
      'بالضغط هنا توافق على إرسال نيّتك — وفي قراءة الفنجان صورة فنجانك — '
      'إلى خدمة ذكاء اصطناعي تابعة لطرف ثالث لكتابة التفسير. '
      'اضغط هنا لقراءة سياسة الخصوصية.';
  @override
  String get splashTagline => 'نكشف أسرار بختك…';
  @override
  String get editProfileTitle => 'الاسم وشهر الميلاد';
  @override
  String get audioCardTitle => 'صوت خلفي';
  @override
  String get audioCardSubtitle => 'هادئ وغير مزعج؛ أطفئه متى شئت.';
  @override
  String get historyLookback => 'نظرة إلى الوراء';
  @override
  String get historyCounting => 'نعدّ الآن…';
  @override
  String get historyAiNote => 'كتب المساعد هذه الجملة من إحصاء فؤولك نفسها.';
  @override
  String get notifTitle => 'التذكيرات';
  @override
  String get notifMutedNote => 'لن نرسل شيئًا حتى تطلب ذلك.';
  @override
  String get notifDaily => 'فأل اليوم';
  @override
  String get notifStreak => 'حين أغيب بضعة أيام';
  @override
  String get notifWeekly => 'نظرة على الأسبوع المنصرم';
  @override
  String get notifUnmute => 'أخبرني مجددًا';
  @override
  String get notifMuteWeek => 'لا شيء لأسبوع';
  @override
  String get reflectTitle => 'اكتب لنفسك';
  @override
  String get reflectHint => 'ما تشاء…';
  @override
  String get reflectSave => 'دوّن';
  @override
  String get reflectSaved => 'دُوِّن';
  @override
  String get reflectPrivacy =>
      'هذه الملاحظة خاصة: لا تُشارَك ولا تُبنى عليها اقتراحات.';
  @override
  String notifQuiet(String from, String to) => 'لا رسائل بين $from و$to.';
  @override
  String get legalTerms => 'الشروط';
  @override
  String get legalPrivacy => 'الخصوصية';
  @override
  String get legalAbout => 'حول';
  @override
  String get legalContact => 'تواصل';
  @override
  String get aboutTitle => 'حول بخت‌نگار';
  @override
  String get contactTitle => 'تواصل معنا';
  @override
  String get privacyUpdated => 'آخر تحديث: يوليو 2026';
  @override
  String get legalUnderstood => 'فهمت';
  @override
  String get contactChannel => 'قناة تيليجرام';
  @override
  String get contactBot => 'بوت بخت‌نگار';
  @override
  String get contactEmailTile => 'بريد الدعم (المس للنسخ)';
  @override
  String get contactVersionTile => 'نسخة التطبيق';
  @override
  String get contactReport => 'الإبلاغ عن مشكلة';
  @override
  String get contactReportEmailSubject => 'بلاغ عن مشكلة في بخت‌نگار';
  @override
  String get contactEmailCopied => 'نُسخ البريد.';
  @override
  String get termsHero =>
      'بخت‌نگار لا يتحمّل أي مسؤولية.\nالقرار في حياتك لك وحدك.';
  @override
  String get aboutHero =>
      'بخت‌نگار — الفأل وأسرار الحياة.\nلحظة هادئة لك وحدك.';
  @override
  String get privacyHero =>
      'خصوصيتك أمر جاد عندنا.\nأقل البيانات، فقط ليعمل الفأل.';
  @override
  String get contactHero => 'سؤال أو اقتراح أو مشكلة؟\nنحن هنا إلى جانبك.';
  @override
  String get disclaimerBody =>
      'فؤول بخت‌نگار للتسلية والتأمل الشخصي فقط، ولا ينبغي أن تكون أساسًا '
      'لقرارات الحياة المهمة.';
  @override
  String versionLine(String v) => 'الإصدار $v';
  @override
  String legalCopyright(String year) =>
      '© بخت‌نگار $year — جميع الحقوق محفوظة.';
  @override
  String get badgeSpecial => 'مميز';
}

/// Turkish — natural, warm İstanbul Turkish; LTR.
class TrStrings extends AppStrings {
  const TrStrings(super.locale);

  @override
  String get appTitle => 'Fal';
  @override
  String get splashPreparing => 'Hazırlanıyor…';
  @override
  String get exploreTitle => 'Keşfet';
  @override
  String get ritualTitle => 'Ritüel';
  @override
  String get readingTitle => 'Falın';
  @override
  String get profileTitle => 'Profil';
  @override
  String get placeholderNotice => 'Bu bölüm sonraki aşamalarda yapılacak.';
  @override
  String get routeNotFoundTitle => 'Bu sayfayı bulamadık';
  @override
  String get routeNotFoundBody =>
      'Adres değişmiş olabilir. Keşfet sayfasına dönebilirsin.';
  @override
  String get actionBackToExplore => 'Fallara dön';
  @override
  String get actionRetry => 'Tekrar dene';
  @override
  String get startupFailedTitle => 'Uygulama başlatılamadı';
  @override
  String get exploreSubtitle => 'Kendine sakin bir an.';
  @override
  String get comingSoon => 'Çok yakında';
  @override
  String get comingSoonDetail => 'Bu ritüel çok yakında hazır olacak.';
  @override
  String get readingSealedTitle => 'Niyetin alındı.';
  @override
  String get readingSealedBody =>
      'Falın tamamı bir sonraki aşamada burada olacak.';
  @override
  String get actionSave => 'Kaydet';
  @override
  String get actionShare => 'Paylaş';
  @override
  String get readingUnavailableTitle => 'Bu fal şu an görülemiyor';
  @override
  String get readingUnavailableBody => 'Falını görmek için ritüelden gir.';
  @override
  String get startupFailedBody =>
      'Verilerin güvende. Bir kez daha dener misin?';
  @override
  String get errorReassurance => 'Verilerin güvende.';
  @override
  String get savedToHistory => 'Geçmişine kaydedildi.';
  @override
  String get historyTitle => 'Geçmiş';
  @override
  String get historyEmptyTitle => 'Burada henüz fal yok';
  @override
  String get historyEmptyBody => 'İlk falın, bu defterin başlangıcı.';
  @override
  String get historyEmptyAction => 'İlk falını al';
  @override
  String get historyLoadMore => 'Daha fazla';
  @override
  String get intentionsTitle => 'Niyetlerim';
  @override
  String get intentionsEmptyTitle => 'Henüz niyetin yok';
  @override
  String get intentionsEmptyBody =>
      'Faldan önce fısıldadığın her niyet burada kalır.';
  @override
  String get savedTitle => 'Kaydedilen fallar';
  @override
  String get savedEmptyTitle => 'Henüz bir şey kaydetmedin';
  @override
  String get savedEmptyBody => 'Saklamak istediğin her fal burada toplanır.';
  @override
  String get savedSaveTooltip => 'Kaydet';
  @override
  String get savedRemoveTooltip => 'Kaydedilenlerden çıkar';
  @override
  String get savedToast => 'Kaydedildi';
  @override
  String get savedError => 'Kaydedilemedi; tekrar dene';
  @override
  String get historyClearTooltip => 'Geçmişi temizle';
  @override
  String get coffeeCaptureHint =>
      'Fincanı ters çevir, dibinin oturmasını bekle, sonra fincanın '
      'dibinin fotoğrafını çek.';
  @override
  String get coffeeTakePhoto => 'Fotoğraf çek';
  @override
  String get coffeeFromGallery => 'Galeriden seç';
  @override
  String get coffeeRetake => 'Yeniden çek';
  @override
  String get coffeeGuideTitle => 'Sembol rehberi';
  @override
  String get coffeeGuideIntro =>
      'Fincanı kendin de okumak istersen bu semboller sana yol gösterir.';
  @override
  String get historyClearTitle => 'Tüm geçmiş silinsin mi?';
  @override
  String get historyClearBody =>
      'Geçmişteki tüm falların kalıcı olarak silinir ve geri alınamaz.';
  @override
  String get historyClearConfirm => 'Sil';
  @override
  String get historyDeleteTooltip => 'Bu falı sil';
  @override
  String get historyDeleteTitle => 'Bu fal silinsin mi?';
  @override
  String get historyDeleteBody => 'Bu fal kalıcı olarak silinir.';
  @override
  String get historyDeleteConfirm => 'Sil';
  @override
  String get actionCancel => 'Vazgeç';
  @override
  String get authOutsideTelegramBody =>
      'Giriş için uygulamayı Telegram içinden aç.';
  @override
  String get authRejectedBody => 'Giriş doğrulanamadı; tekrar dene.';
  @override
  String get navProfile => 'Profil';
  @override
  String get navFortunes => 'Fallar';
  @override
  String get navHome => 'Ana Sayfa';
  @override
  String get navHistory => 'Geçmiş';
  @override
  String get navTerms => 'Kurallar';
  @override
  String get settingsTitle => 'Ayarlar';
  @override
  String get actionBack => 'Geri';
  @override
  String get personalizeTitle => 'BakhtNegar sana nasıl seslensin?';
  @override
  String get personalizeNameHint => 'Adın ya da sevdiğin bir isim';
  @override
  String get personalizeMonthQuestion => 'Doğum ayın?';
  @override
  String get personalizeNote =>
      'Paylaştıkların falını daha isabetli ve kişisel yapar.';
  @override
  String get personalizeGo => 'Hadi başlayalım';
  @override
  String get personalizeSaving => 'Kaydediliyor…';
  @override
  String get personalizeSkip => 'Kaydetmek istemiyorum';
  @override
  String get homeSeeAll => 'Tümünü gör';
  @override
  String get searchFortunesHint => 'Fal ara';
  @override
  String get homeGuestName => 'Baht yolcusu';
  @override
  String get fortuneSoonToast => 'Bu fal yakında açılıyor';
  @override
  String get accessSheetTitle => 'Falını nasıl alacağını seç';
  @override
  String get accessAdOptionTitle => 'Reklamla ücretsiz';
  @override
  String get accessAdOptionBody => 'Kısa bir reklam izle, falını ücretsiz al.';
  @override
  String get accessAdButton => 'Reklamı izle, falını al';
  @override
  String get accessLimitTitle => 'Bugünün ücretsiz falları bitti';
  @override
  String get accessLimitBody => 'Yarın yeni ücretsiz fallar için tekrar gel.';
  @override
  String get actionOkay => 'Tamam';
  @override
  String get accessNoAdTitle => 'Şu an izlenecek reklam yok';
  @override
  String get accessNoAdBody => 'Birazdan tekrar dene.';
  @override
  String get accessRetryLabel => 'Tekrar dene';
  @override
  String get shareBrandLine => '🔮 BakhtNegar';
  @override
  String get shareCopied => 'Fal metni kopyalandı; istediğin yere gönder.';
  @override
  String get shareFailed => 'Paylaşım olmadı; tekrar dene.';
  @override
  String get profileSoonToast => 'Bu bölüm yakında açılıyor';
  @override
  String get profileHistory => 'Fal geçmişi';
  @override
  String get profileSupportAbout => 'Destek ve hakkımızda';
  @override
  String get profileSeeker => 'Hakikat arayıcısı';
  @override
  String get profileEditTooltip => 'İsim ve doğum ayını düzenle';
  @override
  String get profileRecsTitle => 'Kendi fallarımdan öneriler';
  @override
  String get profileRecsBody => 'Kapalıyken hiçbir öneri oluşturulmaz.';
  @override
  String get inviteShareText => 'BakhtNegar ile her gün fal ve istihare ✨';
  @override
  String get inviteTitle => 'Arkadaşlarını davet et';
  @override
  String get inviteBody => 'BakhtNegar\'ı arkadaşlarınla paylaş';
  @override
  String get socialTelegram => 'Telegram kanalı';
  @override
  String get socialInstagram => 'Instagram';
  @override
  String profileSeekerBorn(String month) =>
      '$month doğumlu · Hakikat arayıcısı';
  @override
  String profileBorn(String month) => '$month doğumlu';
  @override
  String get nextStripTitle => 'Bundan sonra';
  @override
  String get reasonFamily => 'Az önce okuduğunla aynı aileden';
  @override
  String get reasonUntried => 'Henüz denemedin';
  @override
  String get reasonAgain => 'Daha önce okudun; belki yine';
  @override
  String get dayPartMornings => 'sabahları';
  @override
  String get dayPartNoons => 'öğlenleri';
  @override
  String get dayPartEvenings => 'akşamları';
  @override
  String get dayPartNights => 'geceleri';
  @override
  String get onboardingNameQuestion =>
      'BakhtNegar sana hangi isimle seslensin?';
  @override
  String get onboardingMonthQuestion => 'Doğum ayın hangisi?';
  @override
  String get onboardingPersonalNote =>
      'Bundan sonra falların biraz daha kişisel olacak.';
  @override
  String get actionContinue => 'Devam';
  @override
  String reasonHabit(String when) => 'Bunu en çok $when okuyorsun';
  @override
  String onboardingWelcome(String name) => 'Hoş geldin, $name.';
  @override
  String get failureNetwork =>
      'Bağlantı kurulamadı. Bağlantını kontrol edip yeniden dene.';
  @override
  String get failureTimeout => 'Biraz uzun sürdü. Yeniden dene.';
  @override
  String get failureAuth => 'Devam etmek için yeniden giriş yap.';
  @override
  String get failureNotFound => 'Aradığın şey bulunamadı.';
  @override
  String get failureValidation => 'Girdi eksik; bir kez daha gözden geçir.';
  @override
  String get failureConflict => 'Bu istek zaten kaydedildi.';
  @override
  String get failureRateLimited => 'Biraz bekle ve yeniden dene.';
  @override
  String get failureCoins =>
      'Bu okuma için jetonların yetmiyor. Bilgilerin güvende.';
  @override
  String get failureSubscription => 'Bu bölüm abonelikle açılır.';
  @override
  String get failureStorage => 'Kaydetme başarısız oldu.';
  @override
  String get failureUnknown =>
      'Bir sorun oluştu. Bilgilerin güvende; yeniden dene.';
  @override
  String get searchHintFull => 'Hangi falı arıyorsun?';
  @override
  String get voiceListening => 'Dinliyorum…';
  @override
  String get voiceMicDenied =>
      'Mikrofon izni verilmedi; tarayıcı ayarlarından aç.';
  @override
  String get voiceNothingHeard => 'Bir şey duyamadım; tekrar söyle ya da yaz.';
  @override
  String get voiceUnsupported => 'Tarayıcın sesli girişi desteklemiyor.';
  @override
  String get voiceFailed => 'Şu an olmadı; bir kez daha dene.';
  @override
  String get voiceStopTooltip => 'Durdur';
  @override
  String get voiceSearchTooltip => 'Sesli arama';
  @override
  String get clearTooltip => 'Temizle';
  @override
  String get searchNoMatch =>
      'Bu adla bir şey bulunamadı; aşağıdaki listeden seç.';
  @override
  String get searchAsking => 'Soruyorum…';
  @override
  String get searchAskAssistant => 'Asistana sor';
  @override
  String get adPreparing => 'Reklam hazırlanıyor...';

  @override
  String get aiConsentNote =>
      'Buna dokunarak niyetinin — kahve falında ise fincanının fotoğrafının — '
      'yorumu yazmak üzere üçüncü taraf bir yapay zekâ hizmetine '
      'gönderilmesini kabul edersin. Gizlilik politikası için buraya dokun.';
  @override
  String get splashTagline => 'Bahtının sırları aralanıyor…';
  @override
  String get editProfileTitle => 'İsim ve doğum ayı';
  @override
  String get audioCardTitle => 'Ortam sesi';
  @override
  String get audioCardSubtitle => 'Sakin ve rahatsız etmez; istediğinde kapat.';
  @override
  String get historyLookback => 'Geçmişe bir bakış';
  @override
  String get historyCounting => 'Sayıyorum…';
  @override
  String get historyAiNote =>
      'Bu cümleyi asistan, kendi fallarının sayımından yazdı.';
  @override
  String get notifTitle => 'Hatırlatmalar';
  @override
  String get notifMutedNote => 'Sen istemedikçe mesaj göndermeyiz.';
  @override
  String get notifDaily => 'Bugünün falı';
  @override
  String get notifStreak => 'Birkaç gün uğramadığımda';
  @override
  String get notifWeekly => 'Geçen haftaya bir bakış';
  @override
  String get notifUnmute => 'Yine haber ver';
  @override
  String get notifMuteWeek => 'Bir hafta bir şey gönderme';
  @override
  String get reflectTitle => 'Kendin için yaz';
  @override
  String get reflectHint => 'İçinden ne geliyorsa…';
  @override
  String get reflectSave => 'Not al';
  @override
  String get reflectSaved => 'Alındı';
  @override
  String get reflectPrivacy =>
      'Bu not özeldir: paylaşılmaz ve içinden öneri üretilmez.';
  @override
  String notifQuiet(String from, String to) =>
      '$from ile $to arasında mesaj gelmez.';
  @override
  String get legalTerms => 'Şartlar';
  @override
  String get legalPrivacy => 'Gizlilik';
  @override
  String get legalAbout => 'Hakkında';
  @override
  String get legalContact => 'İletişim';
  @override
  String get aboutTitle => 'BakhtNegar hakkında';
  @override
  String get contactTitle => 'Bize ulaş';
  @override
  String get privacyUpdated => 'Son güncelleme: Temmuz 2026';
  @override
  String get legalUnderstood => 'Anladım';
  @override
  String get contactChannel => 'Telegram kanalı';
  @override
  String get contactBot => 'BakhtNegar botu';
  @override
  String get contactEmailTile => 'Destek e-postası (kopyalamak için dokun)';
  @override
  String get contactVersionTile => 'Uygulama sürümü';
  @override
  String get contactReport => 'Sorun bildir';
  @override
  String get contactReportEmailSubject => 'BakhtNegar sorun bildirimi';
  @override
  String get contactEmailCopied => 'E-posta kopyalandı.';
  @override
  String get termsHero =>
      'BakhtNegar sorumluluk kabul etmez.\nTüm kararlar senindir.';
  @override
  String get aboutHero =>
      'BakhtNegar — fal ve hayatın sırları.\nKendine ait sakin bir an.';
  @override
  String get privacyHero =>
      'Gizliliğin bizim için ciddidir.\nEn az veri, yalnızca fal için.';
  @override
  String get contactHero => 'Soru, öneri ya da sorun mu var?\nTam buradayız.';
  @override
  String get disclaimerBody =>
      'BakhtNegar falları yalnızca eğlence ve kişisel düşünme içindir; önemli '
      'yaşam kararlarına dayanak yapılmamalıdır.';
  @override
  String versionLine(String v) => 'Sürüm $v';
  @override
  String legalCopyright(String year) =>
      '© BakhtNegar $year — tüm hakları saklıdır.';
  @override
  String get badgeSpecial => 'Özel';
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      const ['fa', 'en', 'ar', 'tr'].contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings.forLocale(locale);

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}

extension AppStringsX on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}
