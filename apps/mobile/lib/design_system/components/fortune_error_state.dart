import 'package:flutter/material.dart';
import '../foundations/app_spacing.dart';
import 'fortune_button.dart';

/// Every error answers three questions: what happened, what can I do, and is
/// my data safe (doc 51 §19.5). Raw codes and stack traces never appear here.
class FortuneErrorState extends StatelessWidget {
  const FortuneErrorState({
    super.key,
    required this.message,
    this.reassurance,
    this.retryLabel,
    this.onRetry,
  });

  final String message;
  final String? reassurance;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (reassurance != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                reassurance!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null && retryLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FortuneButton(
                label: retryLabel!,
                onPressed: onRetry,
                variant: FortuneButtonVariant.secondary,
                fullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
