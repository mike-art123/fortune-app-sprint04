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
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      const ['fa', 'en', 'ar', 'tr'].contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) async {
    return switch (locale.languageCode) {
      'en' => EnStrings(locale),
      'ar' => ArStrings(locale),
      'tr' => TrStrings(locale),
      _ => AppStrings(locale),
    };
  }

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}

extension AppStringsX on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}
