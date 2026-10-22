/// Fiche de révision pour la préparation à la soutenance (jury).
class Flashcard {
  final int? id;
  final int? internshipId;
  final String question;
  final String answer;
  final String category;     // ex: 'technique', 'reglementaire', 'communication'
  final double ease;         // facteur de facilité (SM-2 simplifié)
  final int interval;        // jours avant prochaine révision
  final int repetitions;
  final int dueDate;         // millisecondsSinceEpoch
  final DateTime createdAt;

  const Flashcard({
    this.id,
    this.internshipId,
    required this.question,
    required this.answer,
    this.category = '',
    this.ease = 2.5,
    this.interval = 0,
    this.repetitions = 0,
    required this.dueDate,
    required this.createdAt,
  });

  Flashcard copyWith({
    int? id,
    int? internshipId,
    String? question,
    String? answer,
    String? category,
    double? ease,
    int? interval,
    int? repetitions,
    int? dueDate,
    DateTime? createdAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      internshipId: internshipId ?? this.internshipId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      ease: ease ?? this.ease,
      interval: interval ?? this.interval,
      repetitions: repetitions ?? this.repetitions,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'internship_id': internshipId,
      'question': question,
      'answer': answer,
      'category': category,
      'ease': ease,
      'interval': interval,
      'repetitions': repetitions,
      'due_date': dueDate,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Flashcard.fromMap(Map<String, Object?> map) {
    return Flashcard(
      id: map['id'] is int ? map['id'] as int : null,
      internshipId: map['internship_id'] is int ? map['internship_id'] as int : null,
      question: map['question'] as String? ?? '',
      answer: map['answer'] as String? ?? '',
      category: map['category'] as String? ?? '',
      ease: map['ease'] is num ? (map['ease'] as num).toDouble() : 2.5,
      interval: map['interval'] is int ? map['interval'] as int : 0,
      repetitions: map['repetitions'] is int ? map['repetitions'] as int : 0,
      dueDate: map['due_date'] is int ? map['due_date'] as int : 0,
      createdAt: map['created_at'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
    );
  }

  bool get isDue => dueDate <= DateTime.now().millisecondsSinceEpoch;
}
