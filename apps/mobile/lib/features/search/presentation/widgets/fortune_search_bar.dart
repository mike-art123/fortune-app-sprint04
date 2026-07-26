import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/platform/speech_event.dart';
import '../../../../core/platform/speech_input.dart';
import '../../../../design_system/foundations/app_duration.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../domain/fortune_search.dart';
import '../../domain/search_action.dart';
import '../../domain/search_intent.dart';

/// The search bar over «همه فال‌ها» (scope §2 and §3).
///
/// It answers while you type, tolerates the Arabic ي/ك, نیم‌فاصله and a typo,
/// understands a whole sentence when no name matches, and can be spoken to
/// where the browser allows it. It never navigates on raw text: a tap resolves
/// to a validated action first. Quiet by default — results appear only when
/// something was asked.
class FortuneSearchBar extends StatefulWidget {
  const FortuneSearchBar({
    super.key,
    this.speech = const PlatformSpeechInput(),
  });

  /// The microphone. Injected so a test can speak without a browser.
  final SpeechInput speech;

  @override
  State<FortuneSearchBar> createState() => _FortuneSearchBarState();
}

class _FortuneSearchBarState extends State<FortuneSearchBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  List<FortuneSearchResult> _results = const [];
  SearchIntentMatch? _intent;
  StreamSubscription<SpeechEvent>? _voice;
  String? _voiceNote;
  bool _listening = false;
  bool _asked = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    // Leaving the screen must also close the microphone, not just forget it.
    _voice?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final results = FortuneSearch.query(value);
    setState(() {
      _asked = value.trim().isNotEmpty;
      _results = results;
      // Names first: a sentence only reaches the intent rules when the index
      // has nothing to say (scope §2 pipeline order).
      _intent = results.isEmpty ? SearchIntents.match(value) : null;
    });
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _asked = false;
      _results = const [];
      _intent = null;
      _voiceNote = null;
    });
  }

  void _startListening() {
    if (_listening) return;
    setState(() {
      _listening = true;
      _voiceNote = null;
    });
    _voice = widget.speech
        .listen(locale: 'fa-IR', silence: const Duration(seconds: 6))
        .listen(
          _onSpeech,
          onError: (Object _) => _endListening(SpeechEndReason.failed),
        );
  }

  void _onSpeech(SpeechEvent event) {
    switch (event) {
      case SpeechHeard(:final text, :final isFinal):
        _controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        _onChanged(text);
        if (isFinal) _stopListening();
      case SpeechEnded(:final reason):
        _endListening(reason);
    }
  }

  /// The person tapped stop, or the browser settled: close the microphone
  /// quietly, with nothing to explain.
  void _stopListening() {
    _voice?.cancel();
    _voice = null;
    if (mounted && _listening) setState(() => _listening = false);
  }

  void _endListening(SpeechEndReason reason) {
    _voice?.cancel();
    _voice = null;
    if (!mounted) return;
    setState(() {
      _listening = false;
      _voiceNote = _noteFor(reason);
    });
  }

  /// What to say when listening ends badly. Never blames the person, and never
  /// leaves them without a next step.
  static String? _noteFor(SpeechEndReason reason) {
    switch (reason) {
      case SpeechEndReason.denied:
        return 'اجازهٔ میکروفون داده نشد؛ از تنظیمات مرورگر روشنش کن.';
      case SpeechEndReason.noSpeech:
      case SpeechEndReason.timeout:
        return 'چیزی نشنیدم؛ دوباره بگو یا بنویس.';
      case SpeechEndReason.unsupported:
        return 'مرورگرت شنیدن را پشتیبانی نمی‌کند.';
      case SpeechEndReason.failed:
        return 'الان نشد؛ یک‌بار دیگر امتحان کن.';
      case SpeechEndReason.finished:
      case SpeechEndReason.cancelled:
        return null;
    }
  }

  void _run(SearchAction action) {
    final path = switch (action) {
      OpenFortuneAction(:final path) => path,
      OpenDestinationAction(:final path) => path,
      FortuneSoonAction() => null,
      NoSearchAction() => null,
    };
    if (path != null) {
      _focus.unfocus();
      context.push(path);
      return;
    }
    if (action is FortuneSoonAction) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('این فال به‌زودی فعال می‌شود')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    final focused = _focus.hasFocus;
    final intent = _intent;
    final voiceLine = _listening ? 'دارم گوش می‌دهم…' : _voiceNote;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: AppDuration.standard,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            color: c.surfaceElevated.withValues(alpha: 0.45),
            border: Border.all(
              color: focused
                  ? c.goldWarm.withValues(alpha: 0.55)
                  : c.borderSubtle.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 20, color: c.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  onChanged: _onChanged,
                  textInputAction: TextInputAction.search,
                  style: textTheme.bodyLarge,
                  cursorColor: c.goldWarm,
                  decoration: InputDecoration(
                    hintText: 'دنبال چه فالی می‌گردی؟',
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: c.textMuted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsetsDirectional.symmetric(
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              if (widget.speech.isSupported)
                IconButton(
                  onPressed: _listening ? _stopListening : _startListening,
                  tooltip: _listening ? 'توقف' : 'جست‌وجوی صوتی',
                  icon: Icon(
                    _listening ? Icons.stop_circle_outlined : Icons.mic_none,
                    size: 20,
                    color: _listening ? c.goldWarm : c.textMuted,
                  ),
                ),
              if (_asked)
                IconButton(
                  onPressed: _clear,
                  tooltip: 'پاک کردن',
                  icon: Icon(Icons.close, size: 18, color: c.textMuted),
                ),
            ],
          ),
        ),
        if (voiceLine != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.sm,
            ),
            child: Text(
              voiceLine,
              style: textTheme.bodySmall?.copyWith(color: c.textSecondary),
            ),
          ),
        ],
        if (_asked) ...[
          const SizedBox(height: AppSpacing.sm),
          if (_results.isNotEmpty)
            for (final result in _results)
              _SuggestionRow(
                title: result.entry.title,
                subtitle: result.entry.subtitle,
                soon: !result.entry.isOpenable,
                onTap: () => _run(SearchActions.forFortune(result.entry.id)),
              )
          else if (intent != null)
            _SuggestionRow(
              title: intent.label,
              subtitle: intent.hint,
              onTap: () => _run(intent.action),
            )
          else
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.sm,
              ),
              child: Text(
                'با این نام چیزی پیدا نشد؛ از فهرست پایین انتخاب کن.',
                style: textTheme.bodyMedium?.copyWith(color: c.textSecondary),
              ),
            ),
        ],
      ],
    );
  }
}

/// One tappable answer — a fortune the index found, or the screen a sentence
/// asked for. Both name where they lead before they lead there.
class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.soon = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool soon;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (soon)
                  Text(
                    'به‌زودی',
                    style: textTheme.labelSmall?.copyWith(
                      color: c.textSecondary,
                    ),
                  )
                else
                  Icon(Icons.chevron_left, size: 20, color: c.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
