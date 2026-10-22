/// Profil utilisateur (vierge par défaut, aucune donnée pré-remplie).
class UserProfile {
  final String? id;
  final String fullName;
  final String email;
  final String phone;
  final String school;        // établissement de formation
  final String degree;        // diplôme visé
  final String address;
  final String whatsapp;      // numéro WhatsApp de l'admin (support)
  final DateTime? updatedAt;

  const UserProfile({
    this.id,
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.school = '',
    this.degree = '',
    this.address = '',
    this.whatsapp = '+216 28671953',
    this.updatedAt,
  });

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? school,
    String? degree,
    String? address,
    String? whatsapp,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      school: school ?? this.school,
      degree: degree ?? this.degree,
      address: address ?? this.address,
      whatsapp: whatsapp ?? this.whatsapp,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'school': school,
      'degree': degree,
      'address': address,
      'whatsapp': whatsapp,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory UserProfile.fromMap(Map<String, Object?> map) {
    return UserProfile(
      id: map['id'] as String?,
      fullName: map['full_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      school: map['school'] as String? ?? '',
      degree: map['degree'] as String? ?? '',
      address: map['address'] as String? ?? '',
      whatsapp: map['whatsapp'] as String? ?? '+216 28671953',
      updatedAt: map['updated_at'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
    );
  }

  bool get isBlank => fullName.isEmpty && email.isEmpty && school.isEmpty;
}
