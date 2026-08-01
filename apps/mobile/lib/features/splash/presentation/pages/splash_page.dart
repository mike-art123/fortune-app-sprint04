import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_startup_state.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../design_system/components/fortune_error_state.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../controllers/startup_controller.dart';

/// Premium BakhtNegar splash: the full-bleed brand banner with a luxurious,
/// calm loading treatment along the bottom. Held on screen while startup runs
/// (see [StartupController] for the minimum-display + readiness gating); the
/// router cross-fades to Home once startup is ready.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _sweep;
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sweep.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final startup = ref.watch(startupControllerProvider);
    final failed = startup.hasError || startup.valueOrNull is StartupFailed;

    if (failed) {
      return FortuneScaffold(
        child: FortuneErrorState(
          message: s.startupFailedTitle,
          reassurance: s.startupFailedBody,
          retryLabel: s.actionRetry,
          onRetry: () => ref.read(startupControllerProvider.notifier).retry(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppPalette.nightDeep,
      body: _SplashView(sweep: _sweep, breath: _breath),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView({required this.sweep, required this.breath});

  final AnimationController sweep;
  final AnimationController breath;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final barWidth = MediaQuery.sizeOf(context).width * 0.6;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/bg/splash_banner.jpg',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [Color(0x0005070F), Color(0xB305070F)],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomInset + 46,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LoadingBar(sweep: sweep, width: barWidth),
              const SizedBox(height: 18),
              _BreathingText(breath: breath),
            ],
          ),
        ),
      ],
    );
  }
}

/// A hairline gold track with a soft gold→violet highlight and a small star
/// sweeping right-to-left, wrapped in a very gentle glow.
class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.sweep, required this.width});

  final AnimationController sweep;
  final double width;

  @override
  Widget build(BuildContext context) {
    const height = 4.0;
    return SizedBox(
      width: width,
      height: 16,
      child: AnimatedBuilder(
        animation: sweep,
        builder: (context, _) {
          final t = sweep.value;
          final band = width * 0.34;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(height),
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Stack(
                    children: [
                      const ColoredBox(color: Color(0x2AF6DF9A)),
                      Positioned(
                        right: t * (width + band) - band,
                        width: band,
                        top: 0,
                        bottom: 0,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0x00E7C25E),
                                Color(0xE6F6DF9A),
                                Color(0x99A78BFA),
                                Color(0x00A78BFA),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: t * (width - 6),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFDF3D0),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xAAF6DF9A),
                        blurRadius: 9,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BreathingText extends StatelessWidget {
  const _BreathingText({required this.breath});

  final AnimationController breath;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: breath,
      builder: (context, _) {
        return Opacity(
          opacity: 0.68 + 0.32 * breath.value,
          child: Text(
            context.strings.splashTagline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFF6DF9A),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        );
      },
    );
  }
}
