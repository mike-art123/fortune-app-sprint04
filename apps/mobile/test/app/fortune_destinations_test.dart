import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/routing/fortune_destinations.dart';
import 'package:fortune_app/features/fortunes/domain/fortune_registry.dart';

/// One map decides where a fortune leads. The grid and search both read it,
/// so a card and a search result can never disagree — and a malformed id can
/// never become a route.
void main() {
  test('a live fortune leads to its ritual', () {
    expect(FortuneDestinations.pathFor('hafez'), '/ritual/hafez');
    expect(FortuneDestinations.pathFor('dream'), '/ritual/dream');
  });

  test('a guided fortune leads to its guide, not a ritual', () {
    expect(FortuneDestinations.pathFor('coffee'), '/coffee');
    expect(FortuneDestinations.pathFor('elements'), '/elements');
  });

  test('unknown and malformed ids lead nowhere', () {
    expect(FortuneDestinations.pathFor('nope'), isNull);
    expect(FortuneDestinations.pathFor('../admin'), isNull);
    expect(FortuneDestinations.pathFor(''), isNull);
  });

  test('every live fortune in the registry has a destination', () {
    for (final fortune in FortuneRegistry.all.where((f) => f.isAvailable)) {
      expect(
        FortuneDestinations.pathFor(fortune.id),
        isNotNull,
        reason: '${fortune.id} is live and must lead somewhere',
      );
    }
  });
}
