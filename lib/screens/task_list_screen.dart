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
  List<Task> _allTasks = []; // Armazena todas as tarefas do banco
  List<Task> _filteredTasks = []; // Armazena as tarefas a serem exibidas na tela
  
  final _titleController = TextEditingController();
  String _selectedPriority = 'medium';
  TaskFilter _currentFilter = TaskFilter.all;

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  // Função principal para buscar do banco e atualizar a UI
  Future<void> _refreshTasks() async {
    // 1. Busca todas as tarefas do banco de dados
    final tasksFromDb = await DatabaseService.instance.readAll();
    
    // 2. Define o estado com a lista completa E a lista filtrada
    setState(() {
      _allTasks = tasksFromDb;
      _applyFilter();
    });
  }

  // Apenas aplica o filtro na lista que já está em memória
  void _applyFilter() {
    setState(() {
      switch (_currentFilter) {
        case TaskFilter.pending:
          _filteredTasks = _allTasks.where((task) => !task.completed).toList();
          break;
        case TaskFilter.completed:
          _filteredTasks = _allTasks.where((task) => task.completed).toList();
          break;
        case TaskFilter.all:
        default:
          _filteredTasks = List.from(_allTasks);
          break;
      }
    });
  }

  Future<void> _addTask() async {
    if (_titleController.text.trim().isEmpty) return;
    final task = Task(
      title: _titleController.text.trim(),
      priority: _selectedPriority,
    );
    await DatabaseService.instance.create(task);
    _titleController.clear();
    await _refreshTasks(); // Recarrega tudo do banco
  }

  Future<void> _toggleTask(Task task) async {
    final updatedTask = task.copyWith(completed: !task.completed);
    await DatabaseService.instance.update(updatedTask);
    await _refreshTasks(); // Recarrega tudo do banco
  }

  Future<void> _deleteTask(String id) async {
    await DatabaseService.instance.delete(id);
    await _refreshTasks(); // Recarrega tudo do banco
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Minhas Tarefas (${_filteredTasks.length})'),
      ),
      body: Column(
        children: [
          // Área de Adicionar Tarefa
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
                      child: Text(priority[0].toUpperCase() + priority.substring(1)), // Deixa a primeira letra maiúscula
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
          // Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8.0,
              children: TaskFilter.values.map((filter) {
                return FilterChip(
                  label: Text(filter.name[0].toUpperCase() + filter.name.substring(1)), // ex: "All" -> "All"
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