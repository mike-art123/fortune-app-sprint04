import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../application/reflection_controller.dart';
import '../../domain/reflection.dart';

/// «برای خودت بنویس» — the reflection under a finished reading (scope §8).
///
/// Nothing written here is shared, suggested from, or summarised anywhere. The
/// card says so once, plainly, because a promise about privacy is only worth
/// anything if the person can read it.
class ReflectionCard extends ConsumerStatefulWidget {
  const ReflectionCard({required this.readingId, super.key});

  final String readingId;

  @override
  ConsumerState<ReflectionCard> createState() => _ReflectionCardState();
}

class _ReflectionCardState extends ConsumerState<ReflectionCard> {
  final TextEditingController _note = TextEditingController();
  Feeling? _feeling;
  bool _loaded = false;
  bool _saving = false;
  bool _justSaved = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// Fills the field once from what was written before, and never again — an
  /// arriving response must not overwrite what somebody is in the middle of
  /// typing.
  void _adopt(Reflection? existing) {
    if (_loaded) return;
    _loaded = true;
    if (existing == null) return;
    _note.text = existing.note;
    _feeling = existing.feeling;
  }

  Future<void> _save() async {
    final feeling = _feeling;
    if (feeling == null || _note.text.trim().isEmpty) return;

    setState(() => _saving = true);
    final journal = ref.read(journalControllerProvider.notifier);
    final ok = await journal.save(
      readingId: widget.readingId,
      feeling: feeling,
      note: _note.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _justSaved = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    final existing = ref.watch(reflectionForReadingProvider(widget.readingId));
    _adopt(existing.valueOrNull);

    final feeling = _feeling;
    final line = feeling == null
        ? null
        : ref.watch(reflectionLineProvider(feeling)).valueOrNull;

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.lg),
      child: GoldBorderContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'برای خودت بنویس',
              style: textTheme.titleMedium?.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'این یادداشت خصوصی است: جایی به اشتراک گذاشته نمی‌شود و از آن'
              ' پیشنهادی ساخته نمی‌شود.',
              style: textTheme.labelSmall?.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              children: [
                for (final option in Feeling.values)
                  _FeelingChip(
                    label: option.labelFa,
                    selected: option == feeling,
                    onTap: () => setState(() {
                      _feeling = option;
                      _justSaved = false;
                    }),
                  ),
              ],
            ),
            if (line != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                line.text,
                style: textTheme.bodySmall?.copyWith(
                  color: line.tender ? c.goldWarm : c.textSecondary,
                  height: 1.7,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _note,
              maxLines: 5,
              minLines: 3,
              maxLength: 4000,
              style: TextStyle(color: c.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'هرچه دوست داری…',
                hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
                counterText: '',
                filled: true,
                fillColor: c.surfaceElevated.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: _saving ? null : _save,
                child: Text(
                  // Not «ذخیره» — the reading already has one of those, and two
                  // buttons with the same word on one screen is a small lie.
                  _justSaved ? 'ثبت شد' : 'ثبت',
                  style: TextStyle(color: c.goldWarm, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeelingChip extends StatelessWidget {
  const _FeelingChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    return Material(
      color: selected
          ? c.goldWarm.withValues(alpha: 0.18)
          : c.surfaceElevated.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? c.goldWarm : c.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
