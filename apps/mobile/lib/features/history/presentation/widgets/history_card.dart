import 'package:flutter/material.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../design_system/components/fortune_card.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../fortunes/domain/fortune_registry.dart';
import '../../../reading/domain/reading.dart';

/// One remembered reading: the family's accent dot, the title, the Persian
/// date, and a two-line whisper of the text.
class HistoryCard extends StatelessWidget {
  const HistoryCard({super.key, required this.reading, required this.onOpen});

  final Reading reading;
  final VoidCallback onOpen;

  String _date(BuildContext context) {
    final d = reading.createdAt;
    final formatted = '${d.year.toString().padLeft(4, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.day.toString().padLeft(2, '0')}';
    return Localizations.localeOf(context).languageCode == 'fa'
        ? formatted.toPersianDigits
        : formatted;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    final fortune = FortuneRegistry.byId(reading.fortuneId);
    final accent = fortune?.accent ?? c.accentSecondary;
    final locale = Localizations.localeOf(context);

    return FortuneCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  fortune?.title.resolve(locale) ?? reading.fortuneId,
                  style: textTheme.labelMedium?.copyWith(color: c.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _date(context),
                style: textTheme.labelSmall?.copyWith(color: c.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            reading.title,
            style: textTheme.titleMedium?.copyWith(height: 1.6),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            reading.text,
            style: textTheme.bodySmall?.copyWith(color: c.textMuted, height: 1.9),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
