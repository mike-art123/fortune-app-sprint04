import 'package:flutter/material.dart';
import '../../design_system/theme/fortune_theme_extension.dart';
import '../foundations/app_opacity.dart';
import '../foundations/app_radius.dart';
import '../foundations/app_spacing.dart';

/// Calm input (doc 51 §19.4). Validation copy is supportive guidance shown in
/// a neutral tone — it never scolds and never turns the field red by default.
class FortuneTextField extends StatelessWidget {
  const FortuneTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.guidance,
    this.maxLength,
    this.maxLines = 1,
    this.enabled = true,
    this.accentColor,
    this.onChanged,
    this.semanticLabel,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helper;

  /// Supportive guidance (not an "error"). Rendered in secondary text colour.
  final String? guidance;

  final int? maxLength;
  final int maxLines;
  final bool enabled;
  final Color? accentColor;
  final ValueChanged<String>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final accent = accentColor ?? c.accentSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
        ],
        Semantics(
          textField: true,
          label: semanticLabel ?? label ?? hint,
          child: TextField(
            controller: controller,
            enabled: enabled,
            maxLength: maxLength,
            maxLines: maxLines,
            onChanged: onChanged,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              helperText: helper,
              counterText: '',
              filled: true,
              fillColor: c.surfacePrimary,
              contentPadding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: c.borderSubtle.withValues(alpha: AppOpacity.hairline)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: c.borderSubtle.withValues(alpha: AppOpacity.hairline)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: accent.withValues(alpha: 0.5), width: 1.5),
              ),
            ),
          ),
        ),
        if (guidance != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            guidance!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.textSecondary),
          ),
        ],
      ],
    );
  }
}
