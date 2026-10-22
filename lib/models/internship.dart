/// Un stage / une mission professionnelle (tous domaines confondus).
class Internship {
  final int? id;
  final String name;           // Intitulé de stage
  final String field;          // Domaine professionnel (ex: informatique, santé, BTP, commerce…)
  final String supervisor;     // Maître de stage / tuteur
  final String location;       // Entreprise / ville
  final String description;    // Description libre
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  const Internship({
    this.id,
    required this.name,
    required this.field,
    required this.supervisor,
    required this.location,
    this.description = '',
    this.startDate,
    this.endDate,
    required this.createdAt,
  });

  Internship copyWith({
    int? id,
    String? name,
    String? field,
    String? supervisor,
    String? location,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
  }) {
    return Internship(
      id: id ?? this.id,
      name: name ?? this.name,
      field: field ?? this.field,
      supervisor: supervisor ?? this.supervisor,
      location: location ?? this.location,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'name': name,
      'field': field,
      'supervisor': supervisor,
      'location': location,
      'description': description,
      'start_date': startDate?.millisecondsSinceEpoch,
      'end_date': endDate?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Internship.fromMap(Map<String, Object?> map) {
    return Internship(
      id: map['id'] is int ? map['id'] as int : null,
      name: map['name'] as String? ?? '',
      field: map['field'] as String? ?? '',
      supervisor: map['supervisor'] as String? ?? '',
      location: map['location'] as String? ?? '',
      description: map['description'] as String? ?? '',
      startDate: map['start_date'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int)
          : null,
      endDate: map['end_date'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int)
          : null,
      createdAt: map['created_at'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
    );
  }

  factory Internship.fromJson(Map<String, dynamic> json) {
    return Internship(
      id: json['id'] is int ? json['id'] as int : null,
      name: json['name'] as String? ?? '',
      field: json['field'] as String? ?? '',
      supervisor: json['supervisor'] as String? ?? '',
      location: json['location'] as String? ?? '',
      description: json['description'] as String? ?? '',
      startDate: json['start_date'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['start_date'] as int)
          : null,
      endDate: json['end_date'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['end_date'] as int)
          : null,
      createdAt: json['created_at'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'name': name,
      'field': field,
      'supervisor': supervisor,
      'location': location,
      'description': description,
      if (startDate != null) 'start_date': startDate!.millisecondsSinceEpoch,
      if (endDate != null) 'end_date': endDate!.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() => 'Internship(id: $id, name: $name, field: $field)';
}
