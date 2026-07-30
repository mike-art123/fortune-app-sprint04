import 'package:flutter/material.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../design_system/components/fortune_app_bar.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../widgets/legal_footer.dart';
import '../widgets/legal_section.dart';

/// Privacy — what is collected, what is not, and the reader's rights.
/// Written to match what the app actually does; nothing aspirational.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    final s = context.strings;
    final lang = Localizations.localeOf(context).languageCode;

    return FortuneScaffold(
      appBar: FortuneAppBar(title: Text(s.legalPrivacy)),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          GoldBorderContainer(
            glow: true,
            child: Text(
              s.privacyHero,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: c.textPrimary,
                height: 2.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final section in _sectionsFor(lang)) ...[
            LegalSection(title: section.$1, lines: section.$2),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            s.privacyUpdated,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textMuted, fontSize: 11.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          const LegalFooter(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

List<(String, List<String>)> _sectionsFor(String lang) {
  return switch (lang) {
    'en' => _sectionsEn,
    'ar' => _sectionsAr,
    'tr' => _sectionsTr,
    _ => _sections,
  };
}

const _sectionsEn = <(String, List<String>)>[
  (
    'Sign-in and identity',
    [
      'In the Telegram mini app your identity comes from Telegram itself: the '
          'numeric id and the display name. There is no password, and we have '
          'no access to your Telegram account.',
      'In the standalone build (such as Android), guest sign-in uses a random '
          'device id; we ask for neither phone number nor email.',
    ],
  ),
  (
    'What is stored',
    [
      'The readings you take and their history, so you can read them again.',
      'App settings (language, sound, notifications).',
      'Intentions are private: used only to craft that one reading, and their '
          'text never lands in reports or logs.',
    ],
  ),
  (
    'Analytics',
    [
      'Only anonymous, content-free technical events (like «screen opened») '
          'are recorded, to make the app better.',
      'Intention text, reading text and anything personal is never part of '
          'analytics.',
    ],
  ),
  (
    'Ads',
    [
      'An ad shows only when you tap the «watch ad» button yourself; no ad '
          'ever plays automatically.',
      'Ad networks (AdsGram and Monetag) may receive technical identifiers '
          'during playback, under their own policies.',
      'We sell no personal data to ad networks.',
    ],
  ),
  (
    'Cookies and local storage',
    [
      'No tracking cookies. Your device keeps only the settings and the '
          'sign-in key, locally.',
      'Clearing the app or browser data clears these too.',
    ],
  ),
  (
    'Your rights (GDPR)',
    [
      'You have the right to access, correct and erase your data.',
      'For any of them, just message us from the «contact» page; it is done '
          'promptly.',
    ],
  ),
  (
    'California users (CCPA)',
    [
      'Your personal data is neither sold nor «shared», so there is nothing to '
          'opt out of (Do Not Sell).',
    ],
  ),
  (
    'Children',
    [
      'BakhtNegar is for a general audience and knowingly collects no data '
          'from children under 13.',
    ],
  ),
  (
    'Changes',
    [
      'Any meaningful change is announced on this very page; the last-updated '
          'date sits at the bottom.',
    ],
  ),
];

const _sectionsAr = <(String, List<String>)>[
  (
    'الدخول والهوية',
    [
      'في تطبيق تيليجرام المصغر تأتي هويتك من تيليجرام نفسه: المعرف الرقمي '
          'والاسم الظاهر. لا كلمة مرور، ولا نصل إلى حسابك في تيليجرام.',
      'في النسخة المستقلة (مثل أندرويد) يتم دخول الضيف بمعرف جهاز عشوائي؛ لا '
          'نطلب هاتفًا ولا بريدًا.',
    ],
  ),
  (
    'ما الذي يُحفظ',
    [
      'فؤولك وسجلها، لتعود إليها متى شئت.',
      'إعدادات التطبيق (اللغة والصوت والإشعارات).',
      'النيات خاصة: تُستخدم فقط لصنع ذلك الفأل، ولا يُسجل نصها في التقارير أو '
          'السجلات أبدًا.',
    ],
  ),
  (
    'التحليلات',
    [
      'تُسجل فقط أحداث تقنية مجهولة بلا محتوى (مثل «فُتحت الشاشة») لتحسين '
          'التطبيق.',
      'نص النية ونص الفأل وكل ما هو شخصي ليس جزءًا من الإحصاءات أبدًا.',
    ],
  ),
  (
    'الإعلانات',
    [
      'لا يُعرض الإعلان إلا حين تضغط بنفسك زر «مشاهدة الإعلان»؛ لا شيء يعمل '
          'تلقائيًا.',
      'قد تتلقى شبكات الإعلان (AdsGram وMonetag) معرفات تقنية أثناء العرض وفق '
          'سياساتها.',
      'لا نبيع أي بيانات شخصية لشبكات الإعلان.',
    ],
  ),
  (
    'الكوكيز والتخزين المحلي',
    [
      'لا كوكيز تتبع. لا يحفظ جهازك محليًا سوى الإعدادات ومفتاح الدخول.',
      'بمسح بيانات التطبيق أو المتصفح تُمسح هذه أيضًا.',
    ],
  ),
  (
    'حقوقك (GDPR)',
    [
      'لك حق الوصول إلى بياناتك وتصحيحها ومحوها.',
      'يكفي أن تراسلنا من صفحة «التواصل»؛ ننفذ ذلك في أسرع وقت.',
    ],
  ),
  (
    'مستخدمو كاليفورنيا (CCPA)',
    [
      'بياناتك الشخصية لا تُباع ولا «تُشارك»؛ فلا شيء تنسحب منه (Do Not Sell).',
    ],
  ),
  (
    'الأطفال',
    [
      'بخت‌نگار لجمهور عام ولا يجمع عن قصد بيانات من أطفال دون 13 عامًا.',
    ],
  ),
  (
    'التغييرات',
    [
      'يُعلن أي تغيير مهم في هذه الصفحة؛ وتاريخ آخر تحديث في أسفلها.',
    ],
  ),
];

const _sections = <(String, List<String>)>[
  (
    'ورود و هویت',
    [
      'در مینی‌اپ تلگرام، هویت تو از خودِ تلگرام می‌آید: شناسهٔ عددی و '
          'نام نمایشی. رمز عبوری وجود ندارد و ما به حساب تلگرامت '
          'دسترسی نداریم.',
      'در نسخهٔ مستقل (مثل اندروید)، ورود مهمان با یک شناسهٔ تصادفیِ '
          'دستگاه انجام می‌شود؛ نه شماره تلفن می‌خواهیم نه ایمیل.',
    ],
  ),
  (
    'چه چیزی ذخیره می‌شود',
    [
      'فال‌هایی که می‌گیری و تاریخچه‌شان، تا بتوانی دوباره بخوانی‌شان.',
      'تنظیمات برنامه (زبان، صدا، اعلان‌ها).',
      'نیت‌ها خصوصی‌اند: فقط برای ساختن همان فال استفاده می‌شوند و '
          'متنشان هرگز در گزارش‌ها و لاگ‌ها ثبت نمی‌شود.',
    ],
  ),
  (
    'تحلیل و آمار',
    [
      'فقط رویدادهای فنیِ بی‌نام و بدون محتوا (مثل «صفحه باز شد») برای '
          'بهترکردن برنامه ثبت می‌شود.',
      'متن نیت، متن فال و هر چیز شخصی هرگز بخشی از آمار نیست.',
    ],
  ),
  (
    'تبلیغات',
    [
      'تبلیغ فقط وقتی نمایش داده می‌شود که خودت دکمهٔ «دیدن تبلیغ» را '
          'بزنی؛ هیچ تبلیغی خودکار پخش نمی‌شود.',
      'شبکه‌های تبلیغ (AdsGram و Monetag) حین نمایش تبلیغ طبق '
          'سیاست‌های خودشان ممکن است شناسه‌های فنی دریافت کنند.',
      'ما هیچ دادهٔ شخصی‌ای به شبکه‌های تبلیغ نمی‌فروشیم.',
    ],
  ),
  (
    'کوکی و ذخیرهٔ محلی',
    [
      'کوکیِ ردیابی نداریم. روی دستگاه تو فقط تنظیمات و کلید ورود '
          'به‌صورت محلی نگه داشته می‌شود.',
      'با پاک‌کردن دادهٔ برنامه یا مرورگر، این موارد هم پاک می‌شوند.',
    ],
  ),
  (
    'حقوق تو (GDPR)',
    [
      'حق دسترسی، اصلاح و حذف داده‌هایت را داری.',
      'برای هرکدام کافی است از صفحهٔ «تماس» پیام بدهی؛ در اسرع وقت '
          'انجام می‌شود.',
    ],
  ),
  (
    'کاربران کالیفرنیا (CCPA)',
    [
      'دادهٔ شخصی تو فروخته یا «به اشتراک گذاشته» نمی‌شود؛ بنابراین '
          'چیزی برای انصراف (Do Not Sell) وجود ندارد.',
    ],
  ),
  (
    'کودکان',
    [
      'بخت‌نگار برای مخاطب عمومی است و آگاهانه از کودکان زیر ۱۳ سال '
          'داده جمع نمی‌کند.',
    ],
  ),
  (
    'تغییرات',
    [
      'هر تغییر مهمی در همین صفحه اعلام می‌شود؛ تاریخ آخرین '
          'به‌روزرسانی پایین صفحه است.',
    ],
  ),
];

const _sectionsTr = <(String, List<String>)>[
  (
    'Giriş ve kimlik',
    [
      'Telegram mini uygulamasında kimliğin doğrudan Telegram üzerinden gelir: '
          'sayısal kimlik ve görünen ad. Şifre yoktur; hesabına erişimimiz '
          'yoktur.',
      'Bağımsız sürümde (Android gibi) konuk girişi rastgele bir cihaz '
          'kimliğiyle olur; ne telefon ne e-posta isteriz.',
    ],
  ),
  (
    'Neler saklanır',
    [
      'Aldığın fallar ve geçmişi — yeniden okuyabilmen için.',
      'Uygulama ayarları (dil, ses, bildirimler).',
      'Niyetler özeldir: yalnızca o falı üretmek için kullanılır; metni asla '
          'rapor ve kayıtlara girmez.',
    ],
  ),
  (
    'Analitik',
    [
      'Yalnızca içeriksiz, anonim teknik olaylar («ekran açıldı» gibi) '
          'kaydedilir; amaç uygulamayı iyileştirmektir.',
      'Niyet metni, fal metni ve kişisel hiçbir şey istatistiklere girmez.',
    ],
  ),
  (
    'Reklamlar',
    [
      '«Reklam izle» düğmesine kendin dokunmadıkça reklam gösterilmez; hiçbir '
          'reklam kendiliğinden oynamaz.',
      'Reklam ağları (AdsGram ve Monetag) gösterim sırasında kendi '
          'politikaları uyarınca teknik kimlikler alabilir.',
      'Reklam ağlarına hiçbir kişisel veri satmayız.',
    ],
  ),
  (
    'Çerezler ve yerel depolama',
    [
      'Takip çerezi yok. Cihazında yalnızca ayarlar ve giriş anahtarı yerel '
          'olarak durur.',
      'Uygulama ya da tarayıcı verisini silince bunlar da silinir.',
    ],
  ),
  (
    'Hakların (GDPR)',
    [
      'Verilerine erişme, düzeltme ve silme hakkın var.',
      'Her biri için «iletişim» sayfasından yazman yeter; en kısa sürede '
          'yapılır.',
    ],
  ),
  (
    'Kaliforniya kullanıcıları (CCPA)',
    [
      'Kişisel verin satılmaz ve «paylaşılmaz»; bu yüzden vazgeçilecek bir şey '
          'de yok (Do Not Sell).',
    ],
  ),
  (
    'Çocuklar',
    [
      'BakhtNegar genel kitleye yöneliktir; 13 yaş altı çocuklardan bilerek '
          'veri toplamaz.',
    ],
  ),
  (
    'Değişiklikler',
    [
      'Önemli her değişiklik bu sayfada duyurulur; son güncelleme tarihi en '
          'alttadır.',
    ],
  ),
];
