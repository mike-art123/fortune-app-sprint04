import 'app_failure.dart';

/// Resolves a failure into supportive product language (doc 51 §4.5 / §19.5).
/// Every message answers: what happened, what can I do, is my data safe.
/// NOTE: Persian strings live here temporarily until ARB keys are generated;
/// the resolver is the single swap point once `flutter gen-l10n` runs.
abstract final class FailureMessageResolver {
  static String resolve(AppFailure failure) => switch (failure.kind) {
        FailureKind.networkUnavailable => 'ارتباط برقرار نشد. اتصالت را بررسی کن و دوباره تلاش کن.',
        FailureKind.timeout => 'کمی طول کشید. دوباره تلاش کن.',
        FailureKind.unauthorized || FailureKind.forbidden => 'برای ادامه باید دوباره وارد شوی.',
        FailureKind.notFound => 'چیزی که دنبالش بودی پیدا نشد.',
        FailureKind.validation => 'ورودی کامل نیست؛ یک بار دیگر نگاهش کن.',
        FailureKind.conflict => 'این درخواست قبلاً ثبت شده است.',
        FailureKind.rateLimited => 'کمی صبر کن و دوباره تلاش کن.',
        FailureKind.insufficientCoins => 'سکه‌هایت برای این خوانش کافی نیست. اطلاعاتت محفوظ است.',
        FailureKind.subscriptionRequired => 'این بخش با اشتراک باز می‌شود.',
        FailureKind.storage => 'ذخیره‌سازی ممکن نشد.',
        FailureKind.parsing ||
        FailureKind.server ||
        FailureKind.unknown =>
          'مشکلی پیش آمد. اطلاعاتت محفوظ است؛ دوباره تلاش کن.',
      };
}
