import 'package:flutter/material.dart';

import '../foundations/app_effects.dart';
import '../foundations/app_gradients.dart';
import '../foundations/app_radius.dart';
import '../foundations/app_spacing.dart';

/// Primary luxury action — a gold-gradient pill with a soft glow (e.g.
/// «نیت کن»). The label stays visible while loading so context is kept.
class PremiumButton extends StatelessWidget {
  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  static const ink = Color(0xFF2A1C05);
  static const labelStyle = TextStyle(
    color: ink,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );
  static const _radius = BorderRadius.all(Radius.circular(AppRadius.pill));

  bool get _disabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !_disabled,
      label: label,
      child: Opacity(
        opacity: _disabled ? 0.5 : 1,
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            decoration: const BoxDecoration(
              gradient: AppGradients.goldSheen,
              borderRadius: _radius,
              boxShadow: AppEffects.goldGlow,
            ),
            child: InkWell(
              onTap: _disabled ? null : onPressed,
              borderRadius: _radius,
              child: _Body(
                label: label,
                icon: icon,
                isLoading: isLoading,
                fullWidth: fullWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.fullWidth,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final iconData = icon;
    return Container(
      width: fullWidth ? double.infinity : null,
      height: 52,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: isLoading
          ? const _Spinner()
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconData != null) ...[
                  Icon(iconData, size: 18, color: PremiumButton.ink),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(label, style: PremiumButton.labelStyle),
              ],
            ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: PremiumButton.ink,
      ),
    );
  }
}
