/// A generated reading — the domain entity presented to the user.
class Reading {
  const Reading({
    required this.id,
    required this.fortuneId,
    required this.title,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String fortuneId;
  final String title;
  final String text;
  final DateTime createdAt;
}
