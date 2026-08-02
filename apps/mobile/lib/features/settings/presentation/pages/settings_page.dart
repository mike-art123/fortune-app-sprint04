import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/platform/telegram_safe_area.dart';
import '../../../../core/platform/telegram_top_inset.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../shared/widgets/language_selector.dart';
import '../../../audio/presentation/widgets/ambient_audio_card.dart';
import '../../../notifications/presentation/widgets/notification_settings_card.dart';

/// Settings page: ambient sound and notifications. (Personalization stays on
/// the profile — scope §4: one tap, no settings tree to hunt through.)
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // Telegram's control row floats over the mini app; pad the top by the same
  // inset Home and the profile use so the title clears it.
  final _safeArea = telegramSafeArea;

  @override
  void initState() {
    super.initState();
    _safeArea.addListener(_onSafeAreaChanged);
  }

  @override
  void dispose() {
    _safeArea.removeListener(_onSafeAreaChanged);
    super.dispose();
  }

  void _onSafeAreaChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    return Scaffold(
      backgroundColor: AppPalette.nightDeep,
      body: ListView(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.lg,
        ),
        children: [
          SizedBox(height: telegramTopInset(context)),
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                tooltip: context.strings.actionBack,
                icon: Icon(Icons.arrow_back, color: c.goldWarm),
              ),
              Text(
                context.strings.settingsTitle,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          GoldBorderContainer(
            child: Row(
              children: [
                Icon(Icons.language_rounded, color: c.goldWarm, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'زبان · Language',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const LanguagePill(),
              ],
            ),
          ),
          // The ambient beds play through the browser's audio element and the
          // reminders arrive as Telegram messages — two capabilities the Play
          // build does not have. A switch that cannot deliver is a broken
          // promise, so both cards stay web-only; on Android the page keeps
          // only what truly works.
          if (kIsWeb) ...[
            const SizedBox(height: AppSpacing.sm),
            const AmbientAudioCard(),
            const NotificationSettingsCard(),
          ],
        ],
      ),
    );
  }
}
