import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../design_system/components/fortune_button.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';

/// The coffee offering: capture a cup photo, preview it, retake if needed. The
/// picked image is a downscaled data URL; the parent holds it and submits it.
class CupPhotoField extends StatelessWidget {
  const CupPhotoField({
    super.key,
    required this.imageDataUrl,
    required this.onPick,
    required this.accent,
  });

  final String? imageDataUrl;
  final VoidCallback onPick;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final image = imageDataUrl;
    final hasImage = image != null;
    final variant = hasImage
        ? FortuneButtonVariant.secondary
        : FortuneButtonVariant.primary;
    return Column(
      children: [
        if (image != null)
          _Preview(dataUrl: image)
        else
          _Placeholder(accent: accent, hint: s.coffeeCaptureHint),
        const SizedBox(height: AppSpacing.md),
        FortuneButton(
          label: hasImage ? s.coffeeRetake : s.coffeeTakePhoto,
          variant: variant,
          onPressed: onPick,
        ),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.dataUrl});

  final String dataUrl;

  @override
  Widget build(BuildContext context) {
    final bytes = base64Decode(dataUrl.split(',').last);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.memory(
        bytes,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.accent, required this.hint});

  final Color accent;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: 220,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: accent.withValues(alpha: 0.06),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_camera, size: 40, color: accent),
          const SizedBox(height: AppSpacing.md),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
