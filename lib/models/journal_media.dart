/// Un média attaché à une entrée de journal (photo, vidéo ou enregistrement audio).
class JournalMedia {
  final int? id;
  final int entryId;
  final String path;        // chemin fichier local
  final String type;        // 'photo' | 'video' | 'audio'
  final String mimeType;
  final int size;           // octets
  final DateTime createdAt;

  const JournalMedia({
    this.id,
    required this.entryId,
    required this.path,
    required this.type,
    this.mimeType = '',
    this.size = 0,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'entry_id': entryId,
      'path': path,
      'type': type,
      'mime_type': mimeType,
      'size': size,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory JournalMedia.fromMap(Map<String, Object?> map) {
    return JournalMedia(
      id: map['id'] is int ? map['id'] as int : null,
      entryId: map['entry_id'] is int ? map['entry_id'] as int : 0,
      path: map['path'] as String? ?? '',
      type: map['type'] as String? ?? 'photo',
      mimeType: map['mime_type'] as String? ?? '',
      size: map['size'] is int ? map['size'] as int : 0,
      createdAt: map['created_at'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
    );
  }

  bool get isAudio => type == 'audio';
  bool get isVideo => type == 'video';
  bool get isPhoto => type == 'photo';
}
