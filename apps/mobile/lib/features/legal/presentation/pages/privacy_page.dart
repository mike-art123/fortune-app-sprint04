import 'package:flutter/material.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../core/config/monetization_switch.dart';
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
  final all = switch (lang) {
    'en' => _sectionsEn,
    'ar' => _sectionsAr,
    'tr' => _sectionsTr,
    _ => _sections,
  };
  return kMonetizationEnabled ? all : all.where(_notAboutAds).toList();
}

/// See the note in terms_page.dart: with monetization compiled off there is
/// no ad to disclose, so the paragraph naming the ad networks would describe
/// an app the reader is not holding.
bool _notAboutAds((String, List<String>) section) =>
    !section.$2.any((line) => line.contains('AdsGram'));

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
    'Artificial intelligence',
    [
      'To write an interpretation, we send a third-party AI service the '
          'fortune you chose, the intention you wrote, your display language, '
          'the first name you gave us if you gave one, and — for the coffee '
          'reading only — the photograph of your cup. Without this, there is '
          'no reading to give you.',
      'Nothing that identifies you goes with it: no account, no email '
          'address, no phone number, no device or user identifier. The app '
          'holds none of these in the first place.',
      'The photograph of your cup is read once for that reading and is never '
          'stored on our servers.',
      'The source of every fortune — the ghazal, the card, the verse, the '
          'sign — is chosen before the AI is involved, and its only task is '
          'to interpret that source.',
      'Which service? Ask us from the contact page and we will tell you which '
          'provider does this today. If it ever changes, the change is '
          'written on this page.',
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
    'الذكاء الاصطناعي',
    [
      'لكتابة التفسير نرسل إلى خدمة ذكاء اصطناعي تابعة لطرف ثالث: الفأل الذي '
          'اخترته، ونيّتك التي كتبتها، ولغة العرض، والاسم الأول إن أعطيتنا '
          'إياه، وفي قراءة الفنجان وحدها صورة فنجانك. من دون ذلك لا يوجد فأل '
          'يُكتب لك.',
      'ولا يُرسل معها ما يعرّف بك: لا حساب ولا بريد إلكتروني ولا رقم هاتف '
          'ولا معرّف جهاز أو مستخدم. التطبيق لا يملك شيئًا من ذلك أصلًا.',
      'صورة الفنجان تُقرأ مرة واحدة لتلك القراءة ولا تُحفظ على خوادمنا أبدًا.',
      'مصدر كل فأل — الغزل أو البطاقة أو الآية أو العلامة — يُختار قبل تدخّل '
          'الذكاء الاصطناعي، ومهمته الوحيدة تفسير ذلك المصدر.',
      'أي خدمة؟ اسألنا من صفحة الاتصال ونخبرك أي مزوّد يقوم بذلك اليوم. وإن '
          'تغيّر يومًا فسيُكتب التغيير في هذه الصفحة.',
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
    'هوش مصنوعی',
    [
      'برای نوشتنِ تفسیر، این‌ها به یک سرویسِ هوش مصنوعیِ شخصِ ثالث فرستاده '
          'می‌شود: فالی که انتخاب کرده‌ای، نیتی که نوشته‌ای، زبانِ نمایش، '
          'نامِ کوچکی که داده‌ای اگر داده باشی، و فقط در فال قهوه، عکس '
          'فنجانت. بدون این کار، فالی نوشته نمی‌شود.',
      'هیچ چیزی که تو را بشناساند همراهش نمی‌رود: نه حساب، نه ایمیل، نه '
          'شمارهٔ تلفن، نه شناسهٔ دستگاه یا کاربر. برنامه اصلاً هیچ‌کدام را '
          'ندارد.',
      'عکس فنجان یک‌بار برای همان خوانش خوانده می‌شود و هرگز روی سرورهای ما '
          'ذخیره نمی‌شود.',
      'منبعِ هر فال — غزل، کارت، آیه، نشانه — پیش از دخالتِ هوش مصنوعی '
          'انتخاب می‌شود و تنها کارِ آن، تفسیرِ همان منبع است.',
      'کدام سرویس؟ از صفحهٔ «تماس با ما» بپرس تا بگوییم امروز کدام سرویس این '
          'کار را می‌کند. اگر روزی عوض شود، تغییرش در همین صفحه نوشته '
          'می‌شود.',
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
    'Yapay zekâ',
    [
      'Yorumu yazmak için üçüncü taraf bir yapay zekâ hizmetine şunları '
          'gönderiyoruz: seçtiğin fal, yazdığın niyet, görüntü dilin, '
          'verdiysen adın ve yalnızca kahve falında fincanının fotoğrafı. '
          'Bunlar olmadan yazılacak bir fal olmaz.',
      'Yanında seni tanıtan hiçbir şey gitmez: hesap yok, e-posta yok, '
          'telefon numarası yok, cihaz ya da kullanıcı kimliği yok. '
          'Uygulamada bunların hiçbiri zaten bulunmuyor.',
      'Fincanının fotoğrafı o yorum için bir kez okunur ve sunucularımızda '
          'asla saklanmaz.',
      'Her falın kaynağı — gazel, kart, ayet, işaret — yapay zekâ devreye '
          'girmeden önce seçilir; onun tek işi o kaynağı yorumlamaktır.',
      'Hangi hizmet? İletişim sayfasından sor, bugün bunu hangi sağlayıcının '
          'yaptığını söyleyelim. Değişirse değişiklik bu sayfaya yazılır.',
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
