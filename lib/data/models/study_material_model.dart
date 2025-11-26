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

  const StudyMaterial({
    required this.id,
    required this.title,
    required this.type,
    required this.subject,
    required this.format,
    required this.storagePath,
    required this.updatedAt,
    required this.sizeKb,
  });
}

