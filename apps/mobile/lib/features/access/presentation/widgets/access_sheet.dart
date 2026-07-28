import 'package:flutter/material.dart';

import '../../../../design_system/components/luxury_card.dart';
import '../../../../design_system/components/premium_button.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';

/// The rewarded-ad access sheet (spec copy). Returns 'ad' when the user
/// chooses to watch, or null when dismissed. No VIP, no coins, ever.
Future<String?> showAccessSheet(
  BuildContext context, {
  required String fortuneName,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppPalette.nightPanel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadiusDirectional.only(
        topStart: Radius.circular(AppRadius.xl),
        topEnd: Radius.circular(AppRadius.xl),
      ),
    ),
    builder: (sheetContext) => _AccessSheetBody(fortuneName: fortuneName),
  );
}

class _AccessSheetBody extends StatelessWidget {
  const _AccessSheetBody({required this.fortuneName});

  final String fortuneName;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'روش دریافت فال را انتخاب کنید',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fortuneName,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.goldWarm, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Option(
              icon: Icons.play_circle_outline,
              title: 'دریافت رایگان با تبلیغ',
              description:
                  'یک تبلیغ کوتاه ببینید و فال خود را رایگان دریافت کنید.',
              buttonLabel: 'دیدن تبلیغ و گرفتن فال',
              onPressed: () => Navigator.of(context).pop('ad'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    return LuxuryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: c.goldWarm, size: 22),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(color: c.textMuted, fontSize: 12, height: 1.6),
          ),
          const SizedBox(height: AppSpacing.sm),
          PremiumButton(
            label: buttonLabel,
            fullWidth: true,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

/// «سهمیه فال رایگان امروز تمام شده است» — the daily quota is spent; there is
/// nothing to buy, so the reader simply comes back tomorrow (spec copy).
Future<void> showAdLimitDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppPalette.nightPanel,
      title: const Text(
        'سهمیه فال رایگان امروز تمام شده است',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
      content: const Text(
        'فردا دوباره سر بزنید تا فال‌های تازه را رایگان دریافت کنید.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        PremiumButton(
          label: 'باشه',
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    ),
  );
}

/// «در حال حاضر تبلیغی در دسترس نیست» — retry a little later (spec copy).
Future<String?> showAdsExhaustedDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppPalette.nightPanel,
      title: const Text(
        'در حال حاضر تبلیغی در دسترس نیست',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
      content: const Text(
        'کمی بعد دوباره امتحان کنید.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        PremiumButton(
          label: 'تلاش دوباره',
          onPressed: () => Navigator.of(dialogContext).pop('retry'),
        ),
      ],
    ),
  );
}
