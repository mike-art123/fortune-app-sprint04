import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/string_extensions.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../application/notification_controller.dart';
import '../../domain/notification_preferences.dart';

/// «یادآوری‌ها» — what the app may say, and when it must stay quiet (scope §7).
///
/// Nothing here promises anything: every control is a limit. While the
/// settings are unknown or unreachable the card shows nothing at all, rather
/// than a switch sitting in the wrong position.
class NotificationSettingsCard extends ConsumerWidget {
  const NotificationSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.fortuneColors;
    final prefs = ref.watch(notificationControllerProvider).valueOrNull;
    if (prefs == null) return const SizedBox.shrink();

    final controller = ref.read(notificationControllerProvider.notifier);
    final muted = prefs.isMutedAt(DateTime.now());
    final note = muted
        ? 'تا وقتی خودت بخواهی، پیامی نمی‌فرستیم.'
        : _quietSentence(prefs);

    return GoldBorderContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'یادآوری‌ها',
            style: TextStyle(color: c.textPrimary, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            note,
            style: TextStyle(color: c.textMuted, fontSize: 11),
          ),
          const SizedBox(height: AppSpacing.xs),
          _Toggle(
            label: 'فال امروز',
            value: prefs.dailyFortune,
            onChanged: muted ? null : controller.setDailyFortune,
          ),
          _Toggle(
            label: 'وقتی چند روز سر نزدم',
            value: prefs.streakReminder,
            onChanged: muted ? null : controller.setStreakReminder,
          ),
          _Toggle(
            label: 'نگاهی به هفته‌ای که گذشت',
            value: prefs.weeklySummary,
            onChanged: muted ? null : controller.setWeeklySummary,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => controller.mute(muted ? 0 : 168),
              child: Text(
                muted ? 'باز هم خبرم بده' : 'یک هفته چیزی نفرست',
                style: TextStyle(color: c.goldWarm, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A 24-hour clock in Persian digits — «۲۲» reads as a time, «22» does not.
String _hour(int hour) => '${hour.toPersianDigits}:۰۰';

/// The one line that says exactly when the app will stay quiet.
String _quietSentence(NotificationPreferences prefs) {
  final from = _hour(prefs.quietFromHour);
  final to = _hour(prefs.quietToHour);
  return 'بین $from و $to هیچ پیامی نمی‌آید.';
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      dense: true,
      value: value,
      onChanged: onChanged,
      title: Text(
        label,
        style: TextStyle(
          color: onChanged == null ? c.textMuted : c.textPrimary,
          fontSize: 13,
        ),
      ),
      activeTrackColor: c.goldWarm.withValues(alpha: 0.5),
    );
  }
}
