import 'package:flutter/material.dart';
import '../../design_system/theme/fortune_theme_extension.dart';
import '../foundations/app_breakpoints.dart';
import '../foundations/app_spacing.dart';

/// Standard page shell: background, safe area, readable max width, keyboard
/// dismissal (doc 51 §19.1). Long-form content never stretches edge-to-edge.
class FortuneScaffold extends StatelessWidget {
  const FortuneScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.scrollable = false,
    this.padding,
    this.constrainWidth = true,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;
  final bool constrainWidth;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? const EdgeInsetsDirectional.all(AppSpacing.md),
      child: child,
    );

    final bounded = constrainWidth
        ? Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxReadableWidth),
              child: content,
            ),
          )
        : content;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.fortuneColors.backgroundPrimary,
        appBar: appBar,
        body: SafeArea(
          child: scrollable ? SingleChildScrollView(child: bounded) : bounded,
        ),
      ),
    );
  }
}
