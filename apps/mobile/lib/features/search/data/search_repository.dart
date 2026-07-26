import '../../../core/network/api_client.dart';
import '../domain/search_intent.dart';

/// The AI stage of search (scope §2, last stage).
///
/// The server answers with an id or a screen name — never a path. This layer
/// re-validates that answer through the app's own tables, so a route still
/// cannot be invented at either end, and anything unexpected simply becomes
/// "nothing found", which is the ending the search box already had.
class SearchRepository {
  const SearchRepository(this._api);

  final ApiClient _api;

  Future<SearchIntentMatch?> interpret(String query) async {
    final result = await _api.post('/search/interpret', body: {'query': query});
    return result.fold(
      onSuccess: matchFromInterpretation,
      // A search box never shows an error: silence is a fine answer.
      onFailure: (_) => null,
    );
  }
}

/// Pure translation of the server's reply into something tappable, or null.
/// Kept out of the class so it can be tested without a network at all.
SearchIntentMatch? matchFromInterpretation(Map<String, dynamic> json) {
  final kind = json['kind'];
  if (kind == 'fortune') {
    final id = json['fortuneId'];
    return id is String ? SearchIntents.forFortune(id) : null;
  }
  if (kind == 'screen') {
    final screen = json['screen'];
    return screen is String ? SearchIntents.forScreen(screen) : null;
  }
  return null;
}
