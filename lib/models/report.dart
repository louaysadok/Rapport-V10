/// Un rapport généré (chapitres personnalisables + export PDF/DOCX/XML).
class Report {
  final int? id;
  final String title;
  final int? internshipId;
  final String? dateRange;   // libellé de la période couverte
  final DateTime generatedAt;
  final String format;       // 'pdf' | 'docx' | 'xml'
  final String path;         // chemin du fichier exporté

  const Report({
    this.id,
    required this.title,
    this.internshipId,
    this.dateRange,
    required this.generatedAt,
    required this.format,
    required this.path,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'title': title,
      'internship_id': internshipId,
      'date_range': dateRange,
      'generated_at': generatedAt.millisecondsSinceEpoch,
      'format': format,
      'path': path,
    };
  }

  factory Report.fromMap(Map<String, Object?> map) {
    return Report(
      id: map['id'] is int ? map['id'] as int : null,
      title: map['title'] as String? ?? '',
      internshipId: map['internship_id'] is int ? map['internship_id'] as int : null,
      dateRange: map['date_range'] as String?,
      generatedAt: map['generated_at'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['generated_at'] as int)
          : DateTime.now(),
      format: map['format'] as String? ?? 'pdf',
      path: map['path'] as String? ?? '',
    );
  }
}

/// Un chapitre du rapport (ordre personnalisable).
class ReportChapter {
  final int? id;
  final int reportId;
  final String title;
  final String content;      // contenu généré (français, vérifié par FactGuard)
  final int order;
  final bool included;       // inclus à l'export

  const ReportChapter({
    this.id,
    required this.reportId,
    required this.title,
    this.content = '',
    this.order = 0,
    this.included = true,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'report_id': reportId,
      'title': title,
      'content': content,
      'order': order,
      'included': included ? 1 : 0,
    };
  }

  factory ReportChapter.fromMap(Map<String, Object?> map) {
    return ReportChapter(
      id: map['id'] is int ? map['id'] as int : null,
      reportId: map['report_id'] is int ? map['report_id'] as int : 0,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      order: map['order'] is int ? map['order'] as int : 0,
      included: map['included'] == 1,
    );
  }
}
