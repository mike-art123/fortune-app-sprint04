import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/motion/fortune_fade_transition.dart';
import '../../../fortunes/domain/fortune_definition.dart';
import '../../../fortunes/domain/fortune_registry.dart';
import '../widgets/fortune_grid_card.dart';

/// Explore — the manuscript library. A calm, premium two-column grid of
/// fortune "chapters", fully driven by the registry.
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  void _open(BuildContext context, FortuneDefinition fortune) {
    if (!fortune.isAvailable) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(content: Text(context.strings.comingSoonDetail)),
      );
      return;
    }
    context.push(AppRoutes.ritual(fortune.id));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;

    return FortuneScaffold(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          FortuneFadeIn(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.exploreTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => context.push(AppRoutes.historyPath),
                  icon: const Icon(Icons.auto_stories_outlined),
                  tooltip: s.historyTitle,
                ),
                IconButton(
                  onPressed: () => context.push(AppRoutes.walletPath),
                  icon: const Icon(Icons.toll_outlined),
                  tooltip: s.walletTitle,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          FortuneFadeIn(
            duration: const Duration(milliseconds: 360),
            child: Text(
              s.exploreSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.95,
            ),
            itemCount: FortuneRegistry.all.length,
            itemBuilder: (context, index) {
              final fortune = FortuneRegistry.all[index];
              return FortuneFadeIn(
                duration: Duration(milliseconds: 260 + index * 70),
                child: FortuneGridCard(
                  fortune: fortune,
                  onOpen: () => _open(context, fortune),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
