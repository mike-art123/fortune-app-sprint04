import '../../../shared/models/localized_text.dart';

/// The five words the app offers after a reading (scope §8). A closed list, and
/// the same five the server knows.
enum Feeling { calm, hopeful, longing, worried, heavy }

extension FeelingWire on Feeling {
  String get wire => switch (this) {
        Feeling.calm => 'calm',
        Feeling.hopeful => 'hopeful',
        Feeling.longing => 'longing',
        Feeling.worried => 'worried',
        Feeling.heavy => 'heavy',
      };

  LocalizedText get label => switch (this) {
        Feeling.calm => const LocalizedText(
            fa: 'آرام',
            en: 'Calm',
            ar: 'هادئ',
            tr: 'Sakin',
          ),
        Feeling.hopeful => const LocalizedText(
            fa: 'امیدوار',
            en: 'Hopeful',
            ar: 'متفائل',
            tr: 'Umutlu',
          ),
        Feeling.longing => const LocalizedText(
            fa: 'دل‌تنگ',
            en: 'Longing',
            ar: 'مشتاق',
            tr: 'Özlem dolu',
          ),
        Feeling.worried => const LocalizedText(
            fa: 'نگران',
            en: 'Worried',
            ar: 'قلق',
            tr: 'Endişeli',
          ),
        Feeling.heavy => const LocalizedText(
            fa: 'گرفته',
            en: 'Heavy',
            ar: 'مثقل',
            tr: 'Buruk',
          ),
      };

  String get labelFa => label.fa;

  /// The two the app answers with room instead of another question. Nothing is
  /// inferred from what anybody wrote — this follows the word they chose.
  bool get isTender => this == Feeling.worried || this == Feeling.heavy;
}

Feeling? feelingFromWire(String? wire) {
  for (final feeling in Feeling.values) {
    if (feeling.wire == wire) return feeling;
  }
  return null;
}

/// One entry of the journal, as its own author sees it.
class Reflection {
  const Reflection({
    required this.id,
    required this.readingId,
    required this.feeling,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String? readingId;
  final Feeling feeling;
  final String note;
  final DateTime createdAt;

  static Reflection? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final note = json['note'];
    final feeling = feelingFromWire(json['feeling'] as String?);
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    if (id is! String || note is! String || feeling == null) return null;
    if (createdAt == null) return null;
    return Reflection(
      id: id,
      readingId: json['readingId'] as String?,
      feeling: feeling,
      note: note,
      createdAt: createdAt,
    );
  }
}

/// The line under the note: a question for the lighter feelings, and for the
/// heavier ones an acknowledgement that never asks for more.
class ReflectionLine {
  const ReflectionLine({required this.text, required this.tender});

  final String text;
  final bool tender;

  static ReflectionLine? fromJson(Map<String, dynamic> json) {
    final text = json['text'];
    if (text is! String || text.isEmpty) return null;
    return ReflectionLine(text: text, tender: json['tender'] == true);
  }
}

class ReflectionPage {
  const ReflectionPage({required this.items, required this.nextCursor});

  final List<Reflection> items;
  final String? nextCursor;
}
