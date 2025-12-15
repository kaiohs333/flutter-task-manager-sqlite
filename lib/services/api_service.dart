import 'dart:convert';
import 'dart:io' show Platform; // Importar para checar a plataforma
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // URL base que funciona tanto no emulador Android quanto no simulador iOS
  final String _baseUrl = Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';

  Future<List<Task>> getTasks() async {
    final response = await http.get(Uri.parse('$_baseUrl/tasks'));

    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list.map((model) => Task.fromMap(model)).toList();
    } else {
      throw Exception('Failed to load tasks from API');
    }
  }

  Future<Task> createTask(Task task) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(task.toMap()),
    );

    if (response.statusCode == 201) {
      return Task.fromMap(json.decode(response.body));
    } else {
      throw Exception('Failed to create task via API');
    }
  }

  Future<Task> updateTask(Task task) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/tasks/${task.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(task.toMap()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) { // 201 if upserted
      return Task.fromMap(json.decode(response.body));
    } else {
      throw Exception('Failed to update task via API');
    }
  }

  Future<void> deleteTask(String id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/tasks/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete task via API');
    }
  }
}