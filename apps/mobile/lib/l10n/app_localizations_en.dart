// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get walletTitle => 'Wallet';

  @override
  String get profileTitle => 'Profile';

  @override
  String get placeholderNotice => 'This section is built in later phases.';

  @override
  String get routeNotFoundTitle => 'We couldn\'t find that page';

  @override
  String get routeNotFoundBody =>
      'The address may have changed. You can head back to Explore.';

  @override
  String get actionBackToExplore => 'Back to Explore';

  @override
  String get actionRetry => 'Try again';

  @override
  String get startupFailedTitle => 'The app couldn\'t start';

  @override
  String get startupFailedBody => 'Your data is safe. Please try once more.';

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
  String get walletBalanceUnit => 'coins';

  @override
  String get walletDailyRewardTitle => 'Daily gift';

  @override
  String get walletDailyRewardBody =>
      'A few coins each day, for a fresh reading.';

  @override
  String get walletHistoryTitle => 'Transactions';

  @override
  String get walletHistoryEmpty => 'No transactions yet.';

  @override
  String get walletKindStarter => 'Starter credit';

  @override
  String get walletKindDaily => 'Daily gift';

  @override
  String get walletKindSpend => 'Reading';

  @override
  String get walletKindRefund => 'Refund';

  @override
  String get walletSubscriptionActive =>
      'Your subscription is active — readings are covered.';

  @override
  String walletReadingCost(String cost) {
    return 'Each reading costs $cost coins';
  }

  @override
  String get authOutsideTelegramBody =>
      'Open the app from inside Telegram to sign in.';

  @override
  String get authRejectedBody => 'Sign-in was not confirmed; try again.';

  @override
  String get errorInsufficientCoins =>
      'Not enough coins for this reading. Your data is safe.';

  @override
  String get errorSubscriptionRequired =>
      'This area opens with a subscription.';
}
