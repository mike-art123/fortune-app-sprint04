import 'package:flutter/material.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import 'whisper_field.dart';

/// Interior phase 5 — the bespoke offering for two-name fortunes (love,
/// marriage, reconcile). Two whispers are no longer stacked like form fields
/// joined by a bare «و»; instead a quiet bond in the family accent connects
/// them — a hairline meeting a small rotated node — so the pair reads as one
/// relationship, not two inputs.
class PairedNamesField extends StatelessWidget {
  const PairedNamesField({
    super.key,
    required this.first,
    required this.second,
    required this.accent,
    this.firstPlaceholder,
    this.secondPlaceholder,
    this.maxLength = 60,
  });

  final TextEditingController first;
  final TextEditingController second;
  final Color accent;
  final String? firstPlaceholder;
  final String? secondPlaceholder;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WhisperField(
          controller: first,
          accent: accent,
          placeholder: firstPlaceholder,
          maxLength: maxLength,
        ),
        _BondConnector(accent: accent),
        WhisperField(
          controller: second,
          accent: accent,
          placeholder: secondPlaceholder,
          maxLength: maxLength,
        ),
      ],
    );
  }
}

/// A vertical hairline that fades into a small rotated diamond and out again —
/// the visual «bond» between the two names, in the fortune's own accent.
class _BondConnector extends StatelessWidget {
  const _BondConnector({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    Widget line(Alignment begin, Alignment end) {
      return Container(
        width: 1,
        height: 14,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            colors: [
              accent.withValues(alpha: 0),
              accent.withValues(alpha: 0.55),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          line(Alignment.topCenter, Alignment.bottomCenter),
          const SizedBox(height: AppSpacing.xxs),
          Transform.rotate(
            angle: 0.785398,
            child: Container(width: 8, height: 8, color: accent),
          ),
          const SizedBox(height: AppSpacing.xxs),
          line(Alignment.bottomCenter, Alignment.topCenter),
        ],
      ),
    );
  }
}
