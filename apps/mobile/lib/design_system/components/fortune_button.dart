import 'package:flutter/material.dart';
import '../../design_system/theme/fortune_theme_extension.dart';
import '../foundations/app_opacity.dart';
import '../foundations/app_radius.dart';
import '../foundations/app_spacing.dart';

enum FortuneButtonVariant { primary, secondary, tertiary, destructive, text }

/// Primary action component (doc 51 §19.2). The label stays readable while
/// loading so the user never loses context.
class FortuneButton extends StatelessWidget {
  const FortuneButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = FortuneButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = true,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final FortuneButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final String? semanticLabel;

  bool get _disabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final (bg, fg, border) = switch (variant) {
      FortuneButtonVariant.primary => (c.accentPrimary, c.textPrimary, null),
      FortuneButtonVariant.secondary => (c.surfaceElevated, c.textPrimary, c.borderSubtle),
      FortuneButtonVariant.tertiary => (Colors.transparent, c.textPrimary, c.borderSubtle),
      FortuneButtonVariant.destructive => (c.error, Colors.white, null),
      FortuneButtonVariant.text => (Colors.transparent, c.accentSecondary, null),
    };

    return Semantics(
      button: true,
      enabled: !_disabled,
      label: semanticLabel ?? label,
      child: Opacity(
        opacity: _disabled ? AppOpacity.disabled : 1,
        child: SizedBox(
          width: fullWidth ? double.infinity : null,
          height: 52,
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: InkWell(
              onTap: _disabled ? null : onPressed,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Container(
                decoration: border == null
                    ? null
                    : BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: border.withValues(alpha: AppOpacity.hairline * 2)),
                      ),
                alignment: Alignment.center,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading) ...[
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
