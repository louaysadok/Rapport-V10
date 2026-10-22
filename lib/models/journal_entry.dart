/import 'dart:convert';

// Une entrée de journal de bord (une entrée par jour et par stage).
class JournalEntry {
  final int? id;
  final int internshipId;
  final String date;           // ISO 8601 locale: yyyy-MM-dd
  final String title;
  final String content;        // Récit des activités observées / réalisées (faits)
  final int mood;              // 1..5
  final double hours;          // heures passées ce jour
  final String meta;           // JSON: réponses questionnaire adaptatif + ids médias
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalEntry({
    this.id,
    required this.internshipId,
    required this.date,
    required this.title,
    required this.content,
    this.mood = 3,
    this.hours = 0.0,
    this.meta = '{}',
    required this.createdAt,
    required this.updatedAt,
  });

  JournalEntry copyWith({
    int? id,
    int? internshipId,
    String? date,
    String? title,
    String? content,
    int? mood,
    double? hours,
    String? meta,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      internshipId: internshipId ?? this.internshipId,
      date: date ?? this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      hours: hours ?? this.hours,
      meta: meta ?? this.meta,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'internship_id': internshipId,
      'date': date,
      'title': title,
      'content': content,
      'mood': mood,
      'hours': hours,
      'meta': meta,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory JournalEntry.fromMap(Map<String, Object?> map) {
    return JournalEntry(
      id: map['id'] is int ? map['id'] as int : null,
      internshipId: map['internship_id'] is int ? map['internship_id'] as int : 0,
      date: map['date'] as String? ?? '',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      mood: map['mood'] is int ? map['mood'] as int : 3,
      hours: (map['hours'] is num) ? (map['hours'] as num).toDouble() : 0.0,
      meta: map['meta'] as String? ?? '{}',
      createdAt: map['created_at'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
      updatedAt: map['updated_at'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : DateTime.now(),
    );
  }

  /// Réponses du questionnaire adaptatif stockées dans [meta].
  Map<String, dynamic> answers() {
    try {
      return (jsonDecode(meta) as Map<dynamic, dynamic>?)?['answers'] as Map<String, dynamic>? ??
          <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  set answers(Map<String, dynamic> value) {
    final current = <String, dynamic>{};
    try {
      current.addAll(jsonDecode(meta) as Map<dynamic, dynamic>? ?? {});
    } catch (_) {}
    current['answers'] = value;
    meta = jsonEncode(current);
  }

  List<String> mediaIds() {
    try {
      final ids = (jsonDecode(meta) as Map<dynamic, dynamic>?)?['media'] as List<dynamic>?;
      return ids?.whereType<String>().toList() ?? <String>[];
    } catch (_) {
      return <String>[];
    }
  }
}
