import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/components/fortune_app_bar.dart';
import '../../../../design_system/components/fortune_button.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../widgets/legal_footer.dart';

const _supportEmail = 'rezaeiardakanim@gmail.com';
const _supportChannel = 'https://t.me/bakhtnegar';
const _supportBot = 'https://t.me/Bakhtnegarbot';

/// Contact — every way to reach us, and a one-tap way to report a problem.
class ContactPage extends ConsumerWidget {
  const ContactPage({super.key});

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _supportEmail));
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('ایمیل کپی شد.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    final config = ref.watch(appConfigProvider);
    final bridge = ref.watch(telegramBridgeProvider);

    return FortuneScaffold(
      appBar: const FortuneAppBar(title: Text('تماس با ما')),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          GoldBorderContainer(
            glow: true,
            child: Text(
              'سؤال، پیشنهاد یا مشکلی داری؟\n'
              'همین‌جا در کنارت هستیم.',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: c.textPrimary,
                height: 2.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ContactTile(
            icon: Icons.send_rounded,
            title: 'کانال تلگرام',
            value: 't.me/bakhtnegar',
            onTap: () => bridge.openTelegramLink(_supportChannel),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ContactTile(
            icon: Icons.smart_toy_outlined,
            title: 'بات بخت‌نگار',
            value: '@Bakhtnegarbot',
            onTap: () => bridge.openTelegramLink(_supportBot),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ContactTile(
            icon: Icons.mail_outline_rounded,
            title: 'ایمیل پشتیبانی (لمس کن تا کپی شود)',
            value: _supportEmail,
            onTap: () => _copyEmail(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ContactTile(
            icon: Icons.info_outline_rounded,
            title: 'نسخهٔ برنامه',
            value: '${config.appVersion}+${config.buildNumber}',
          ),
          const SizedBox(height: AppSpacing.md),
          FortuneButton(
            label: 'گزارش مشکل',
            onPressed: () => bridge.openTelegramLink(_supportChannel),
          ),
          const SizedBox(height: AppSpacing.lg),
          const LegalFooter(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    return InkWell(
      onTap: onTap,
      child: GoldBorderContainer(
        child: Row(
          children: [
            Icon(icon, color: c.goldWarm, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: c.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
