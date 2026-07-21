import 'package:flutter/material.dart';
import '../../../../design_system/foundations/app_duration.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';

/// The "Whisper" input — the signature of Ritual Entry (ported from the
/// approved React design). Not a form field: borderless, transparent, with a
/// single hairline underneath that warms to the family accent on focus.
/// The user is speaking to themselves, not filling a form.
class WhisperField extends StatefulWidget {
  const WhisperField({
    super.key,
    required this.controller,
    required this.accent,
    this.placeholder,
    this.semanticLabel,
    this.maxLength = 300,
    this.multiline = false,
    this.minLines = 1,
    this.centered = true,
  });

  final TextEditingController controller;
  final Color accent;
  final String? placeholder;
  final String? semanticLabel;
  final int maxLength;
  final bool multiline;
  final int minLines;
  final bool centered;

  @override
  State<WhisperField> createState() => _WhisperFieldState();
}

class _WhisperFieldState extends State<WhisperField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final focused = _focus.hasFocus;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      textField: true,
      label: widget.semanticLabel ?? widget.placeholder,
      child: AnimatedContainer(
        duration: AppDuration.standard,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: focused ? 2 : 1,
              color: focused
                  ? widget.accent.withValues(alpha: 0.6)
                  : c.borderSubtle.withValues(alpha: 0.3),
            ),
          ),
          // A soft moonlight halo under the line on focus — never a box.
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: -10,
                  ),
                ]
              : const [],
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focus,
          maxLength: widget.maxLength,
          maxLines: widget.multiline ? null : 1,
          minLines: widget.multiline ? widget.minLines : 1,
          textAlign: widget.centered ? TextAlign.center : TextAlign.start,
          keyboardType:
              widget.multiline ? TextInputType.multiline : TextInputType.text,
          style:
              (widget.multiline ? textTheme.bodyLarge : textTheme.titleMedium)
                  ?.copyWith(height: 1.9),
          cursorColor: widget.accent,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: textTheme.bodyLarge?.copyWith(color: c.textMuted),
            border: InputBorder.none,
            counterText: '',
            isCollapsed: false,
            contentPadding: const EdgeInsetsDirectional.only(bottom: 8, top: 4),
          ),
        ),
      ),
    );
  }
}
