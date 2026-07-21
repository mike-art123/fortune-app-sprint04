import '../domain/reading.dart';

/// Wire-format mapping for the backend response (data layer only).
abstract final class ReadingDto {
  static Reading fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final fortune = json['fortune'];
    final title = json['title'];
    final reading = json['reading'];
    final createdAt = json['createdAt'];

    if (id is! String ||
        fortune is! String ||
        title is! String ||
        reading is! String) {
      throw const FormatException('reading payload missing required fields');
    }

    return Reading(
      id: id,
      fortuneId: fortune,
      title: title,
      text: reading,
      createdAt: createdAt is String
          ? (DateTime.tryParse(createdAt)?.toLocal() ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
