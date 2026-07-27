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
    this.background,
    this.bottomNavigationBar,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;
  final bool constrainWidth;

  /// Optional full-bleed layer painted behind the body (below the app bar).
  /// Null keeps the plain solid background — existing pages are unaffected.
  final Widget? background;

  /// Tabs for pages that are a destination rather than a detour.
  /// Null keeps the bare shell, so nothing that does not ask changes.
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? const EdgeInsetsDirectional.all(AppSpacing.md),
      child: child,
    );

    final bounded = constrainWidth
        ? Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxReadableWidth,
              ),
              child: content,
            ),
          )
        : content;

    Widget body = SafeArea(
      child: scrollable ? SingleChildScrollView(child: bounded) : bounded,
    );
    final bg = background;
    if (bg != null) {
      // `expand`, not the default `loose`. The backdrop sits in a
      // Positioned.fill, so it does not count towards the Stack's size — the
      // scroll view is the only child that does, and under loose constraints
      // a SingleChildScrollView shrink-wraps its content. The Stack then ends
      // where the content ends, the backdrop with it, and everything below is
      // the Scaffold's flat background showing through. Expanding makes the
      // Stack take the full viewport and hand tight constraints down, so the
      // image reaches the bottom of the screen on every fortune.
      body = Stack(
        fit: StackFit.expand,
        children: [Positioned.fill(child: bg), body],
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.fortuneColors.backgroundPrimary,
        appBar: appBar,
        bottomNavigationBar: bottomNavigationBar,
        body: body,
      ),
    );
  }
}
