import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';

// Enum para controlar o estado do filtro
enum TaskFilter { all, pending, completed }

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  List<Task> _filteredTasks = []; // Lista para exibir as tarefas filtradas
  
  final _titleController = TextEditingController();
  String _selectedPriority = 'medium'; // Prioridade padrão para o dropdown
  TaskFilter _currentFilter = TaskFilter.all; // Filtro inicial

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await DatabaseService.instance.readAll();
    setState(() {
      _tasks = tasks;
      _applyFilter(); // Aplica o filtro atual sempre que as tarefas são carregadas
    });
  }

  void _applyFilter() {
    setState(() {
      switch (_currentFilter) {
        case TaskFilter.pending:
          _filteredTasks = _tasks.where((task) => !task.completed).toList();
          break;
        case TaskFilter.completed:
          _filteredTasks = _tasks.where((task) => task.completed).toList();
          break;
        case TaskFilter.all:
        default:
          _filteredTasks = List.from(_tasks);
          break;
      }
    });
  }

  Future<void> _addTask() async {
    if (_titleController.text.trim().isEmpty) return;

    final task = Task(
      title: _titleController.text.trim(),
      priority: _selectedPriority, // Usa a prioridade selecionada
    );
    await DatabaseService.instance.create(task);
    _titleController.clear();
    _loadTasks(); // Recarrega e aplica o filtro
  }

  Future<void> _toggleTask(Task task) async {
    final updated = task.copyWith(completed: !task.completed);
    await DatabaseService.instance.update(updated);
    _loadTasks();
  }

  Future<void> _deleteTask(String id) async {
    await DatabaseService.instance.delete(id);
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Minhas Tarefas (${_filteredTasks.length})'), // Contador de tarefas
      ),
      body: Column(
        children: [
          // Área de Adicionar Tarefa com Dropdown
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
                // Dropdown para Prioridade
                DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Prioridade',
                    border: OutlineInputBorder(),
                  ),
                  items: Task.priorities.map((String priority) {
                    return DropdownMenuItem<String>(
                      value: priority,
                      child: Text(priority),
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
          // Filtros por Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8.0,
              children: [
                FilterChip(
                  label: const Text('Todas'),
                  selected: _currentFilter == TaskFilter.all,
                  onSelected: (selected) {
                    setState(() => _currentFilter = TaskFilter.all);
                    _applyFilter();
                  },
                ),
                FilterChip(
                  label: const Text('Pendentes'),
                  selected: _currentFilter == TaskFilter.pending,
                  onSelected: (selected) {
                    setState(() => _currentFilter = TaskFilter.pending);
                    _applyFilter();
                  },
                ),
                FilterChip(
                  label: const Text('Concluídas'),
                  selected: _currentFilter == TaskFilter.completed,
                  onSelected: (selected) {
                    setState(() => _currentFilter = TaskFilter.completed);
                    _applyFilter();
                  },
                ),
              ],
            ),
          ),
          // Lista de Tarefas
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