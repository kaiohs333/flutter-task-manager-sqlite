import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/task.dart';
import 'api_service.dart';
import 'database_service.dart';
import 'connectivity_service.dart';

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ApiService _apiService = ApiService();
  final DatabaseService _databaseService = DatabaseService.instance;
  final ConnectivityService _connectivityService = ConnectivityService();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  StreamSubscription? _connectivitySubscription;

  void initialize() {
    _connectivitySubscription = _connectivityService.addListener(_onConnectivityChanged);
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
      // 1. Process local sync queue
      await _processSyncQueue();

      // 2. Fetch all tasks from server and reconcile with local
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
        switch (action) {
          case 'CREATE':
            if (payload != null) {
              final Task localTask = Task.fromMap(json.decode(payload));
              final Task serverTask = await _apiService.createTask(localTask);
              // Update local task with server ID and mark as synced
              await _databaseService.update(serverTask.copyWith(isSynced: true));
              debugPrint('CREATE task $taskId synced. Server ID: ${serverTask.id}');
            }
            break;
          case 'UPDATE':
            if (payload != null) {
              final Task localTask = Task.fromMap(json.decode(payload));
              final Task serverTask = await _apiService.updateTask(localTask);
              // Update local task with server data and mark as synced
              await _databaseService.update(serverTask.copyWith(isSynced: true));
              debugPrint('UPDATE task $taskId synced.');
            }
            break;
          case 'DELETE':
            await _apiService.deleteTask(taskId);
            debugPrint('DELETE task $taskId synced.');
            break;
        }
        await _databaseService.removeFromSyncQueue(queueId);
      } catch (e) {
        debugPrint('Failed to sync item $queueId ($action $taskId): $e');
        // Optionally, mark as failed in queue or retry later
      }
    }
  }

  Future<void> _reconcileWithServer() async {
    debugPrint('Reconciling local tasks with server...');
    final List<Task> serverTasks = await _apiService.getTasks();
    final List<Task> localTasks = await _databaseService.readAll();

    final Map<String, Task> serverTasksMap = {for (var t in serverTasks) t.id!: t};
    final Map<String, Task> localTasksMap = {for (var t in localTasks) t.id!: t};

    // Process tasks from server
    for (final serverTask in serverTasks) {
      final localTask = localTasksMap[serverTask.id];

      if (localTask == null) {
        // Task exists on server but not locally, create it locally
        await _databaseService.create(serverTask.copyWith(isSynced: true));
        debugPrint('Created local task from server: ${serverTask.id}');
      } else {
        // Task exists both locally and on server, apply LWW
        if (serverTask.updatedAt.isAfter(localTask.updatedAt)) {
          // Server version is newer, update local
          await _databaseService.update(serverTask.copyWith(isSynced: true));
          debugPrint('Updated local task ${serverTask.id} from server (LWW).');
        } else if (localTask.updatedAt.isAfter(serverTask.updatedAt) && localTask.isSynced == false) {
          // Local version is newer and not yet synced, push to server
          // This case should ideally be handled by _processSyncQueue,
          // but as a fallback, we ensure it's pushed.
          debugPrint('Local task ${localTask.id} is newer but not synced. Adding to queue for push.');
          await _databaseService.addToSyncQueue(
            localTask.id!,
            'UPDATE',
            payload: json.encode(localTask.toMap()),
          );
        } else {
          // Both are same or local is older and already synced, no action needed
          debugPrint('Task ${serverTask.id} already up-to-date or local is older and synced.');
        }
      }
    }

    // Process tasks that are local but not on server (or deleted on server)
    for (final localTask in localTasks) {
      if (!serverTasksMap.containsKey(localTask.id)) {
        // Task exists locally but not on server (implies it was deleted on server or never pushed)
        // For simplicity, we'll delete it locally if it's not in the sync queue
        // (meaning it wasn't a local delete pending sync).
        final queueItem = (await _databaseService.readSyncQueue()).firstWhereOrNull(
          (item) => item['taskId'] == localTask.id && item['action'] == 'DELETE',
        );

        if (queueItem == null) {
          await _databaseService.delete(localTask.id!);
          debugPrint('Deleted local task ${localTask.id} not found on server.');
        }
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

// Extension to easily find an item in a list
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}