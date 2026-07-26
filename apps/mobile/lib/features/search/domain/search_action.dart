import '../../../app/routing/fortune_destinations.dart';
import '../../fortunes/domain/fortune_registry.dart';

/// What a search result is allowed to do (scope §2 guardrail).
///
/// Typed text never becomes a route. A tap resolves to one of these actions
/// first, and only an id the registry knows — with a destination the shared
/// map approves — can ever turn into navigation.
sealed class SearchAction {
  const SearchAction();
}

/// The fortune leads somewhere real: open [path] (a ritual or its guide).
final class OpenFortuneAction extends SearchAction {
  const OpenFortuneAction({required this.fortuneId, required this.path});

  final String fortuneId;
  final String path;
}

/// The fortune exists but is not live yet — say so, never navigate.
final class FortuneSoonAction extends SearchAction {
  const FortuneSoonAction(this.fortuneId);

  final String fortuneId;
}

/// Nothing trustworthy to do with this input.
final class NoSearchAction extends SearchAction {
  const NoSearchAction();
}

abstract final class SearchActions {
  /// Resolves a fortune id into a safe action. Anything unknown or malformed
  /// resolves to something that cannot navigate.
  static SearchAction forFortune(String fortuneId) {
    final path = FortuneDestinations.pathFor(fortuneId);
    if (path != null) {
      return OpenFortuneAction(fortuneId: fortuneId, path: path);
    }
    return FortuneRegistry.byId(fortuneId) == null
        ? const NoSearchAction()
        : FortuneSoonAction(fortuneId);
  }
}
