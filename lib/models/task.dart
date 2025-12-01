
class Task {
  static const priorities = ['low', 'medium', 'high', 'urgent'];

  final int? id;
  final String title;
  final String description;
  final bool completed;
  final String priority;
  final DateTime createdAt;

  // CAMPOS (CÂMERA)
  final String? photoPath;

  // CAMPOS (SENSORES)
  final DateTime? completedAt;
  final String? completedBy; // 'manual', 'shake'

  // CAMPOS (GPS)
  final double? latitude;
  final double? longitude;
  final String? locationName;

 Task({
    this.id,
    required this.title,
    this.description = '', // Descrição agora é opcional no construtor mas não nula
    this.priority = 'medium',
    this.completed = false,
    DateTime? createdAt,
    this.photoPath,
    this.completedAt,
    this.completedBy,
    this.latitude,
    this.longitude,
    this.locationName,
  }) : createdAt = createdAt ?? DateTime.now();

  // Getters auxiliares
  bool get hasPhoto => photoPath != null && photoPath!.isNotEmpty;
  bool get hasLocation => latitude != null && longitude != null;
  bool get wasCompletedByShake => completedBy == 'shake';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'completed': completed ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'photoPath': photoPath,
      'completedAt': completedAt?.toIso8601String(),
      'completedBy': completedBy,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String, // Roteiro indica 'description' como 'TEXT NOT NULL' no DB
      priority: map['priority'] as String,
      completed: (map['completed'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      photoPath: map['photoPath'] as String?,
      completedAt: map['completedAt'] != null 
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      completedBy: map['completedBy'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      locationName: map['locationName'] as String?,
    );
  }

Task copyWith({
    int? id,
    String? title,
    String? description,
    String? priority,
    bool? completed,
    DateTime? createdAt,
    String? photoPath,
    ValueUpdate<String?>? photoPathGetter,
    DateTime? completedAt,
    ValueUpdate<DateTime?>? completedAtGetter,
    String? completedBy,
    ValueUpdate<String?>? completedByGetter,
    double? latitude,
    ValueUpdate<double?>? latitudeGetter,
    double? longitude,
    ValueUpdate<double?>? longitudeGetter,
    String? locationName,
    ValueUpdate<String?>? locationNameGetter,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      // ---- CORREÇÃO APLICADA AQUI ----
      // Acessamos a propriedade .value em vez de chamar a função
      photoPath: photoPathGetter != null ? photoPathGetter.value : (photoPath ?? this.photoPath),
      completedAt: completedAtGetter != null ? completedAtGetter.value : (completedAt ?? this.completedAt),
      completedBy: completedByGetter != null ? completedByGetter.value : (completedBy ?? this.completedBy),
      latitude: latitudeGetter != null ? latitudeGetter.value : (latitude ?? this.latitude),
      longitude: longitudeGetter != null ? longitudeGetter.value : (longitude ?? this.longitude),
      locationName: locationNameGetter != null ? locationNameGetter.value : (locationName ?? this.locationName),
    );
  }
}

// Classe auxiliar para permitir "limpar" um campo usando copyWith
class ValueUpdate<T> {
  final T value;
  const ValueUpdate(this.value);
}