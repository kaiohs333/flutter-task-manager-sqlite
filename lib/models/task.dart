import 'package:uuid/uuid.dart';

class Task {
  static const priorities = ['low', 'medium', 'high', 'urgent'];

  final String? id; // Alterado de int? para String?
  final String title;
  final String description;
  final bool completed;
  final String priority;
  final DateTime createdAt;
  final DateTime updatedAt; // Novo campo
  final bool isSynced; // Novo campo

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
    String? id, // Alterado de int? para String?
    required this.title,
    this.description = '',
    this.priority = 'medium',
    this.completed = false,
    DateTime? createdAt,
    DateTime? updatedAt, // Novo parâmetro
    this.isSynced = false, // Novo parâmetro
    this.photoPath,
    this.completedAt,
    this.completedBy,
    this.latitude,
    this.longitude,
    this.locationName,
  })  : id = id ?? const Uuid().v4(), // Gerar UUID se não fornecido
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(); // Inicializar updatedAt

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
      'updatedAt': updatedAt.toIso8601String(), // Incluir updatedAt
      'isSynced': isSynced ? 1 : 0, // Incluir isSynced
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
      id: map['id'] as String?, // Alterado de int? para String?
      title: map['title'] as String,
      description: map['description'] as String,
      priority: map['priority'] as String,
      completed: (map['completed'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String), // Parsear updatedAt
      isSynced: (map['isSynced'] as int) == 1, // Parsear isSynced
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
    String? id, // Alterado de int? para String?
    String? title,
    String? description,
    String? priority,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt, // Novo parâmetro
    bool? isSynced, // Novo parâmetro
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
      updatedAt: updatedAt ?? this.updatedAt, // Incluir updatedAt
      isSynced: isSynced ?? this.isSynced, // Incluir isSynced
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