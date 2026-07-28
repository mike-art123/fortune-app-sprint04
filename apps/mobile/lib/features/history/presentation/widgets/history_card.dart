import 'package:flutter/material.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../design_system/components/fortune_art.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_layout.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../fortunes/domain/fortune_registry.dart';
import '../../../reading/domain/reading.dart';

/// Text now sits on artwork rather than a flat panel, so it carries the same
/// shadow the image-led cards use to stay readable over a photograph.
const _overArt = [Shadow(color: Color(0xCC000000), blurRadius: 8)];

/// One remembered reading, wearing its own fortune's artwork: the family's
/// accent dot, the title, the Persian date, and a two-line whisper of the text.
///
/// The journal used to be a column of identical navy panels, so recognising a
/// reading meant reading it. The picture does that work at a glance.
class HistoryCard extends StatelessWidget {
  const HistoryCard({
    super.key,
    required this.reading,
    required this.onOpen,
    this.onDelete,
    this.onUnsave,
  });

  final Reading reading;
  final VoidCallback onOpen;

  /// When set, a small delete control rides in the card's header row; null
  /// keeps the card read-only.
  final VoidCallback? onDelete;

  /// When set, a small "remove from saved" control rides in the header row.
  final VoidCallback? onUnsave;

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
    final fortune = FortuneRegistry.byId(reading.fortuneId);
    final accent = fortune?.accent ?? context.fortuneColors.accentSecondary;
    final shape = BorderRadius.circular(AppRadius.lg);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: AppLayout.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: Material(
          color: AppPalette.nightPanel,
          child: InkWell(
            onTap: onOpen,
            child: Stack(
              // Loose on purpose. A history card has no fixed ratio — a long
              // title makes a taller card — so the text decides the height and
              // the artwork stretches to whatever that turns out to be. An
              // expanding Stack would demand a bounded height the list cannot
              // give it.
              children: [
                Positioned.fill(child: _artwork(accent)),
                Padding(
                  padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                  child: _content(context, accent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The fortune's own image, veiled just enough that two lines of body text
  /// stay readable on top of it. Every fortune the API can return has artwork,
  /// and FortuneArt paints its own gradient if one ever goes missing.
  Widget _artwork(Color accent) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FortuneArt(id: reading.fortuneId, accent: accent, scrim: false),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppPalette.nightDeep.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }

  Widget _content(BuildContext context, Color accent) {
    final textTheme = Theme.of(context).textTheme;
    final fortune = FortuneRegistry.byId(reading.fortuneId);
    final locale = Localizations.localeOf(context);
    final label = fortune?.title.resolve(locale) ?? reading.fortuneId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.95),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                  shadows: _overArt,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _date(context),
              style: textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.70),
                shadows: _overArt,
              ),
            ),
            if (onUnsave != null) _unsaveButton(context),
            if (onDelete != null) _deleteButton(context),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          reading.title,
          style: textTheme.titleMedium?.copyWith(
            height: 1.6,
            color: Colors.white,
            shadows: _overArt,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          reading.text,
          style: textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.80),
            height: 1.9,
            shadows: _overArt,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _unsaveButton(BuildContext context) {
    return IconButton(
      onPressed: onUnsave,
      tooltip: context.strings.savedRemoveTooltip,
      icon: const Icon(Icons.bookmark),
      iconSize: 18,
      color: Colors.white.withValues(alpha: 0.7),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  /// A compact trash control that sits at the header's trailing edge and
  /// takes its own taps, so touching it deletes rather than opens the card.
  Widget _deleteButton(BuildContext context) {
    return IconButton(
      onPressed: onDelete,
      tooltip: context.strings.historyDeleteTooltip,
      icon: const Icon(Icons.delete_outline),
      iconSize: 18,
      color: Colors.white.withValues(alpha: 0.7),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
