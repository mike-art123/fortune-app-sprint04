import '../../../core/result/result.dart';

/// One intention the user whispered before a reading.
class Intention {
  const Intention({
    required this.id,
    required this.fortuneId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String fortuneId;
  final String text;
  final DateTime createdAt;
}

/// Contract the application layer depends on — never the implementation.
abstract interface class IntentionsRepository {
  Future<Result<List<Intention>>> list();
}
