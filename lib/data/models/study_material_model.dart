enum StudyMaterialType {
  lecture,
  presentation,
  document,
  video,
  homework,
}

class StudyMaterial {
  final String id;
  final String title;
  final StudyMaterialType type;
  final String subject;
  final String format;
  final String storagePath;
  final DateTime updatedAt;
  final int sizeKb;
  final String? teacherId; // Поле для индекса в Firestore

  const StudyMaterial({
    required this.id,
    required this.title,
    required this.type,
    required this.subject,
    required this.format,
    required this.storagePath,
    required this.updatedAt,
    required this.sizeKb,
    this.teacherId,
  });

  factory StudyMaterial.fromJson(Map<String, dynamic> json) {
    return StudyMaterial(
      id: json['id'],
      title: json['title'],
      type: StudyMaterialType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'document'),
        orElse: () => StudyMaterialType.document,
      ),
      subject: json['subject'],
      format: json['format'],
      storagePath: json['storagePath'],
      updatedAt: DateTime.parse(json['updatedAt']),
      sizeKb: json['sizeKb']?.toInt() ?? 0,
      teacherId: json['teacherId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'subject': subject,
      'format': format,
      'storagePath': storagePath,
      'updatedAt': updatedAt.toIso8601String(),
      'sizeKb': sizeKb,
      if (teacherId != null) 'teacherId': teacherId,
    };
  }
}

