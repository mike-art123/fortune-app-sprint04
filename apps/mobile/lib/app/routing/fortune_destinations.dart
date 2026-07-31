import '../../features/fortunes/domain/fortune_registry.dart';
import 'app_routes.dart';

/// Where a fortune actually leads — one map shared by the «همه فال‌ها» grid
/// and by search, so a card and a search result can never disagree.
abstract final class FortuneDestinations {
  /// Fortunes that open a real guide instead of a live ritual. These are never
  /// «به‌زودی»: they lead somewhere real. Coffee left this list the day its
  /// vision backend went live — its card now opens the photo ritual itself.
  static const Map<String, String> guides = {
    'elements': AppRoutes.elementsPath,
  };

  /// The route this fortune opens, or null when there is nowhere honest to go
  /// (unknown id, malformed id, or a fortune that is not live yet).
  static String? pathFor(String id) {
    if (!RouteParams.isValidId(id)) return null;
    final guide = guides[id];
    if (guide != null) return guide;
    final fortune = FortuneRegistry.byId(id);
    if (fortune == null || !fortune.isAvailable) return null;
    return AppRoutes.ritual(id);
  }
}
