import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import 'api_service.dart';
import 'database_service.dart';
import 'connectivity_service.dart';

class SyncService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DatabaseService _databaseService = DatabaseService.instance;
  final ConnectivityService _connectivityService;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  SyncService(this._connectivityService) {
    _connectivityService.addListener(_onConnectivityChanged);
  }

  void initialize() {
    _onConnectivityChanged(); // Check initial status
  }

  void _onConnectivityChanged() {
    if (_connectivityService.isOnline) {
      debugPrint('Connectivity changed to ONLINE. Starting sync...');
      _startSync();
    } else {
      debugPrint('Connectivity changed to OFFLINE.');
    }
  }

  Future<void> _startSync() async {
    if (_isSyncing) {
      debugPrint('Sync already in progress. Skipping.');
      return;
    }
    _isSyncing = true;
    notifyListeners();
    debugPrint('Starting synchronization process...');

    try {
      await _processSyncQueue();
      await _reconcileWithServer();
      debugPrint('Synchronization process completed successfully.');
    } catch (e) {
      debugPrint('Synchronization failed: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _processSyncQueue() async {
    final queue = await _databaseService.readSyncQueue();
    debugPrint('Processing sync queue with ${queue.length} items.');

    for (final item in queue) {
      final int queueId = item['id'];
      final String taskId = item['taskId'];
      final String action = item['action'];
      final String? payload = item['payload'];

      try {
        debugPrint('Syncing item $queueId: $action $taskId');
        switch (action) {
          case 'CREATE':
            if (payload != null) {
              final Task localTask = Task.fromMap(json.decode(payload));
              await _apiService.createTask(localTask);
              await _databaseService.setSynced(taskId, true);
              debugPrint('CREATE task $taskId synced.');
            }
            break;
          case 'UPDATE':
            if (payload != null) {
              final Task localTask = Task.fromMap(json.decode(payload));
              await _apiService.updateTask(localTask);
              await _databaseService.setSynced(taskId, true);
              debugPrint('UPDATE task $taskId synced.');
            }
            break;
          case 'DELETE':
            await _apiService.deleteTask(taskId);
            debugPrint('DELETE task $taskId synced.');
            // A tarefa já foi deletada localmente, só precisamos remover da fila.
            break;
        }
        await _databaseService.removeFromSyncQueue(queueId);
      } catch (e) {
        debugPrint('Failed to sync item $queueId ($action $taskId): $e');
        // O item permanece na fila para a próxima tentativa.
      }
    }
  }

  Future<void> _reconcileWithServer() async {
    debugPrint('Reconciling local tasks with server...');
    final List<Task> serverTasks = await _apiService.getTasks();
    final List<Task> localTasks = await _databaseService.readAll();

    final Map<String, Task> serverTasksMap = {for (var t in serverTasks) t.id!: t};
    final Map<String, Task> localTasksMap = {for (var t in localTasks) t.id!: t};

    // 1. Reconciliar do servidor para o cliente (LWW)
    for (final serverTask in serverTasks) {
      final localTask = localTasksMap[serverTask.id];

      if (localTask == null) {
        // Tarefa existe no servidor, mas não localmente -> Adicionar localmente
        debugPrint('Server task ${serverTask.id} not found locally. Creating.');
        await _databaseService.create(serverTask.copyWith(isSynced: true));
      } else {
        // Tarefa existe em ambos -> verificar qual é mais recente
        if (serverTask.updatedAt.isAfter(localTask.updatedAt)) {
          // Versão do servidor é mais nova -> Atualizar local
          debugPrint('Server task ${serverTask.id} is newer. Updating local task.');
          await _databaseService.update(serverTask.copyWith(isSynced: true));
        }
      }
    }

    // 2. Limpar tarefas locais que foram deletadas no servidor
    for (final localTask in localTasks) {
      if (!serverTasksMap.containsKey(localTask.id) && localTask.isSynced) {
        // Tarefa sincronizada localmente não existe no servidor -> Deletar localmente
        debugPrint('Synced local task ${localTask.id} not in server. Deleting locally.');
        await _databaseService.delete(localTask.id!);
      }
    }
  }

  @override
  void dispose() {
    _connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}