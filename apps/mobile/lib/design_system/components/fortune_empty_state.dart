import 'package:flutter/material.dart';
import '../foundations/app_spacing.dart';
import 'fortune_button.dart';

/// Empty states are hopeful and actionable, never a dead end.
class FortuneEmptyState extends StatelessWidget {
  const FortuneEmptyState({
    super.key,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            if (description != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(description!,
                  style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FortuneButton(
                label: actionLabel!,
                onPressed: onAction,
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
