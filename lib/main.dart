import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // IMPORTANTE: Nova importação
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/task_list_screen.dart';

Future<void> main() async {
  // Garante que os bindings do Flutter estejam prontos
  WidgetsFlutterBinding.ensureInitialized();

  // --- SOLUÇÃO PARA O ERRO ---
  // Verifica se o app está rodando na WEB
  if (kIsWeb) {
    // Define o databaseFactory para usar a implementação web
    databaseFactory = databaseFactoryFfiWeb;
  } 
  // Se não for web (ou seja, for desktop: Windows, macOS, Linux)
  else {
    // Inicializa o FFI para desktop
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