import 'package:flutter/material.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../fortunes/domain/fortune_registry.dart';
import '../../domain/intention.dart';

/// One remembered intention: the words the user offered, and for which fortune.
class IntentionCard extends StatelessWidget {
  const IntentionCard({super.key, required this.intention});

  final Intention intention;

  String _date(BuildContext context) {
    final d = intention.createdAt;
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
    final fortune = FortuneRegistry.byId(intention.fortuneId);
    final locale = Localizations.localeOf(context);
    final label = fortune?.title.resolve(locale) ?? intention.fortuneId;

    return GoldBorderContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: c.goldWarm, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _date(context),
                style: TextStyle(color: c.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            intention.text,
            style: TextStyle(color: c.textPrimary, fontSize: 14, height: 1.7),
          ),
        ],
      ),
    );
  }
}
