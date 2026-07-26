import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/foundations/app_duration.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../domain/fortune_search.dart';
import '../../domain/search_action.dart';

/// The search bar over «همه فال‌ها» (scope §2, deterministic stage).
///
/// It answers while you type, tolerates the Arabic ي/ك, نیم‌فاصله and a typo,
/// and never navigates on raw text: a tap resolves to a validated action
/// first. Quiet by default — results appear only when something was asked.
class FortuneSearchBar extends StatefulWidget {
  const FortuneSearchBar({super.key});

  @override
  State<FortuneSearchBar> createState() => _FortuneSearchBarState();
}

class _FortuneSearchBarState extends State<FortuneSearchBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  List<FortuneSearchResult> _results = const [];
  bool _asked = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      _asked = value.trim().isNotEmpty;
      _results = FortuneSearch.query(value);
    });
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _asked = false;
      _results = const [];
    });
  }

  void _open(FortuneSearchEntry entry) {
    final action = SearchActions.forFortune(entry.id);
    switch (action) {
      case OpenFortuneAction(:final path):
        _focus.unfocus();
        context.push(path);
      case FortuneSoonAction():
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('این فال به‌زودی فعال می‌شود')),
        );
      case NoSearchAction():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    final focused = _focus.hasFocus;

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
              if (_asked)
                IconButton(
                  onPressed: _clear,
                  tooltip: 'پاک کردن',
                  icon: Icon(Icons.close, size: 18, color: c.textMuted),
                ),
            ],
          ),
        ),
        if (_asked) ...[
          const SizedBox(height: AppSpacing.sm),
          if (_results.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.sm,
              ),
              child: Text(
                'با این نام چیزی پیدا نشد؛ از فهرست پایین انتخاب کن.',
                style: textTheme.bodyMedium?.copyWith(color: c.textSecondary),
              ),
            )
          else
            for (final result in _results)
              _ResultRow(entry: result.entry, onTap: () => _open(result.entry)),
        ],
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.entry, required this.onTap});

  final FortuneSearchEntry entry;
  final VoidCallback onTap;

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
                        entry.title,
                        style: textTheme.titleMedium?.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!entry.isOpenable)
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
