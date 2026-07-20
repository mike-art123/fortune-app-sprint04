import 'package:flutter/material.dart';
import '../../design_system/theme/fortune_theme_extension.dart';
import '../foundations/app_spacing.dart';

/// Calm loading indicator. Never used to disguise uncertainty in financial or
/// entitlement operations (doc 51 §35).
class FortuneLoading extends StatelessWidget {
  const FortuneLoading({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: c.accentSecondary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
