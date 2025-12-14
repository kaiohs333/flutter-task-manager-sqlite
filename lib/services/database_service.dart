import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5, // AUMENTAMOS A VERSÃO PARA 5
      onCreate: _createDB,
      onUpgrade: _onUpgrade, // NOVO: Especifica a função de migração
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY'; // ID agora é TEXT para UUID
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE tasks (
        id $idType,
        title $textType,
        description $textType,
        priority $textType,
        completed $intType,
        createdAt $textType,
        updatedAt $textType, -- Adicionado para LWW
        isSynced $intType DEFAULT 0, -- 0 para false, 1 para true
        photoPath TEXT,
        completedAt TEXT,
        completedBy TEXT,
        latitude REAL,
        longitude REAL,
        locationName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        taskId TEXT NOT NULL,
        action TEXT NOT NULL, -- 'CREATE', 'UPDATE', 'DELETE'
        payload TEXT, -- JSON string of the task data for CREATE/UPDATE
        timestamp TEXT NOT NULL
      )
    ''');
  }

  // NOVA FUNÇÃO DE MIGRAÇÃO
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Atualizando banco da v$oldVersion para v$newVersion...');
    // Migração incremental para cada versão
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN photoPath TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE tasks ADD COLUMN completedAt TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN completedBy TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE tasks ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE tasks ADD COLUMN longitude REAL');
      await db.execute('ALTER TABLE tasks ADD COLUMN locationName TEXT');
    }
    if (oldVersion < 5) {
      // Adiciona updatedAt e isSynced à tabela tasks
      await db.execute('ALTER TABLE tasks ADD COLUMN updatedAt TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN isSynced INTEGER DEFAULT 0');

      // Cria a tabela sync_queue
      await db.execute('''
        CREATE TABLE sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          taskId TEXT NOT NULL,
          action TEXT NOT NULL, -- 'CREATE', 'UPDATE', 'DELETE'
          payload TEXT, -- JSON string of the task data for CREATE/UPDATE
          timestamp TEXT NOT NULL
        )
      ''');
    }
    print('✅ Banco migrado de v$oldVersion para v$newVersion');
  }

  // --- MÉTODOS CRUD ATUALIZADOS ---

  Future<Task> create(Task task) async {
    final db = await instance.database;
    await db.insert('tasks', task.toMap());
    // Adiciona à fila de sincronização
    await addToSyncQueue(task.id!, 'CREATE', payload: json.encode(task.toMap()));
    return task;
  }

  Future<Task?> read(String id) async { // MUDANÇA: de int id para String id
    final db = await instance.database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Task>> readAll() async {
    final db = await instance.database;
    const orderBy = 'createdAt DESC';
    final result = await db.query('tasks', orderBy: orderBy);
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<int> update(Task task) async {
    final db = await instance.database;
    final result = await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    // Adiciona à fila de sincronização
    if (result > 0) {
      await addToSyncQueue(task.id!, 'UPDATE', payload: json.encode(task.toMap()));
    }
    return result;
  }

  Future<int> delete(String id) async { // MUDANÇA: de int id para String id
    final db = await instance.database;
    // Adiciona à fila de sincronização ANTES de deletar localmente
    await addToSyncQueue(id, 'DELETE');
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- MÉTODOS DA FILA DE SINCRONIZAÇÃO ---

  Future<void> addToSyncQueue(
      String taskId, String action, {String? payload}) async {
    final db = await instance.database;
    await db.insert('sync_queue', {
      'taskId': taskId,
      'action': action,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    });
    print('Adicionado à fila de sincronização: $action para taskId $taskId');
  }

  Future<List<Map<String, dynamic>>> readSyncQueue() async {
    final db = await instance.database;
    final result = await db.query('sync_queue', orderBy: 'timestamp ASC');
    return result;
  }

  Future<void> removeFromSyncQueue(int id) async {
    final db = await instance.database;
    await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Removido da fila de sincronização: id $id');
  }

  // --- MÉTODOS DE APOIO À SINCRONIZAÇÃO ---

  Future<void> setSynced(String taskId, bool isSynced) async {
    final db = await instance.database;
    await db.update(
      'tasks',
      {'isSynced': isSynced ? 1 : 0},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<Task?> getTaskById(String id) async {
    final db = await instance.database;
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  // MÉTODO ADICIONADO PARA COMPATIBILIDADE
  Future<List<Task>> getTasksNearLocation({
    required double latitude,
    required double longitude,
    required int radiusInMeters,
  }) async {
    // Implementação de placeholder para evitar erros de compilação.
    // Esta funcionalidade não faz parte dos requisitos principais.
    print('Função "getTasksNearLocation" não implementada.');
    return [];
  }
}