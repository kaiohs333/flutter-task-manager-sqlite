import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';

enum TaskFilter { all, pending, completed }

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  
  final _titleController = TextEditingController();
  String _selectedPriority = 'medium';
  TaskFilter _currentFilter = TaskFilter.all;

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  Future<void> _refreshTasks() async {
    developer.log('UI: Iniciando _refreshTasks...', name: 'TaskListScreen');
    final tasksFromDb = await DatabaseService.instance.readAll();
    developer.log('UI: _refreshTasks recebeu ${tasksFromDb.length} tarefas do DB.', name: 'TaskListScreen');
    if (mounted) {
      setState(() {
        developer.log('UI: setState em _refreshTasks está executando.', name: 'TaskListScreen');
        _allTasks = tasksFromDb;
        _applyFilter();
      });
    }
  }

  void _applyFilter() {
    switch (_currentFilter) {
      case TaskFilter.pending:
        _filteredTasks = _allTasks.where((task) => !task.completed).toList();
        break;
      case TaskFilter.completed:
        _filteredTasks = _allTasks.where((task) => task.completed).toList();
        break;
      default:
        _filteredTasks = List.from(_allTasks);
        break;
    }
  }

  Future<void> _addTask() async {
    developer.log('UI: _addTask chamado.', name: 'TaskListScreen');
    if (_titleController.text.trim().isEmpty) {
      developer.log('UI: _addTask abortado, título vazio.', name: 'TaskListScreen');
      return;
    }
    
    try {
      final task = Task(
        title: _titleController.text.trim(),
        priority: _selectedPriority,
      );
      developer.log('UI: Criando objeto da tarefa: ${task.toMap()}', name: 'TaskListScreen');
      await DatabaseService.instance.create(task);
      _titleController.clear();
      await _refreshTasks();
    } catch (e, s) {
      developer.log('UI: ERRO em _addTask: $e', name: 'TaskListScreen', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar a tarefa: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleTask(Task task) async {
    final updatedTask = task.copyWith(completed: !task.completed);
    await DatabaseService.instance.update(updatedTask);
    await _refreshTasks();
  }

  Future<void> _deleteTask(String id) async {
    await DatabaseService.instance.delete(id);
    await _refreshTasks();
  }
  
  @override
  Widget build(BuildContext context) {
    developer.log('UI: Método build chamado. Tarefas filtradas: ${_filteredTasks.length}', name: 'TaskListScreen');
    return Scaffold(
      appBar: AppBar(
        title: Text('Minhas Tarefas (${_filteredTasks.length})'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Nova tarefa...',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addTask(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addTask,
                      child: const Text('Adicionar'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Prioridade',
                    border: OutlineInputBorder(),
                  ),
                  items: Task.priorities.map((String priority) {
                    return DropdownMenuItem<String>(
                      value: priority,
                      child: Text(priority[0].toUpperCase() + priority.substring(1)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedPriority = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8.0,
              children: TaskFilter.values.map((filter) {
                return FilterChip(
                  label: Text(filter.name[0].toUpperCase() + filter.name.substring(1)),
                  selected: _currentFilter == filter,
                  onSelected: (selected) {
                    setState(() {
                      _currentFilter = filter;
                      _applyFilter();
                    });
                  },
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTasks.length,
              itemBuilder: (context, index) {
                final task = _filteredTasks[index];
                return ListTile(
                  leading: Checkbox(
                    value: task.completed,
                    onChanged: (_) => _toggleTask(task),
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.completed ? TextDecoration.lineThrough : null,
                      color: task.completed ? Colors.grey : null,
                    ),
                  ),
                  subtitle: Text('Prioridade: ${task.priority}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteTask(task.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}