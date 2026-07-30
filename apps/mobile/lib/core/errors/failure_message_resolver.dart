import '../../app/localization/app_strings.dart';
import 'app_failure.dart';

/// Resolves a failure into supportive product language (doc 51 §4.5 / §19.5).
/// Every message answers: what happened, what can I do, is my data safe.
/// Messages come from [AppStrings], so every failure speaks the app locale.
abstract final class FailureMessageResolver {
  static String resolve(AppFailure failure, AppStrings strings) {
    return switch (failure.kind) {
      FailureKind.networkUnavailable => strings.failureNetwork,
      FailureKind.timeout => strings.failureTimeout,
      FailureKind.unauthorized || FailureKind.forbidden => strings.failureAuth,
      FailureKind.notFound => strings.failureNotFound,
      FailureKind.validation => strings.failureValidation,
      FailureKind.conflict => strings.failureConflict,
      FailureKind.rateLimited => strings.failureRateLimited,
      FailureKind.insufficientCoins => strings.failureCoins,
      FailureKind.subscriptionRequired => strings.failureSubscription,
      FailureKind.storage => strings.failureStorage,
      FailureKind.parsing ||
      FailureKind.server ||
      FailureKind.unknown =>
        strings.failureUnknown,
    };
  }
}
