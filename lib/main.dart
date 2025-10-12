import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// Importa a constante 'kIsWeb' para verificar se estamos na web
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'screens/task_list_screen.dart';

Future<void> main() async {
  // Garante que o Flutter esteja inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // --- SOLUÇÃO PARA O ERRO ---
  // Verifica se NÃO estamos na web para inicializar o FFI.
  // A versão web do sqflite (sqflite_common_ffi_web) se inicializa sozinha.
  if (!kIsWeb) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: const TaskListScreen(),
    );
  }
}