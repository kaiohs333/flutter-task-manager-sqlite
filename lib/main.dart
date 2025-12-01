// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importar provider
import 'screens/task_list_screen.dart';
import 'services/camera_service.dart';
import 'services/connectivity_service.dart'; // Importar ConnectivityService
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async { // 2. Transformar main em async
  // 3. Garantir que o Flutter esteja pronto
  WidgetsFlutterBinding.ensureInitialized();

  // 4. Inicializar o banco de dados para a plataforma correta
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  
  // 5. Inicializar o serviço de câmera
  await CameraService.instance.initialize();

  // 6. Rodar o App
  runApp(
    ChangeNotifierProvider( // Prover ConnectivityService
      create: (context) => ConnectivityService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // Tema customizado para os Cards
        cardTheme: CardThemeData( // Errata do roteiro: CardThemeData não é const
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const TaskListScreen(),
    );
  }
}