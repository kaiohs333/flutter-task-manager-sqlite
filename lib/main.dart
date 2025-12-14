import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/task_list_screen.dart';
import 'services/camera_service.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart'; // Importar SyncService
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  
  await CameraService.instance.initialize();

  // Inicializar serviços com injeção de dependência
  final connectivityService = ConnectivityService();
  final syncService = SyncService(connectivityService);
  syncService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: connectivityService),
        ChangeNotifierProvider.value(value: syncService),
      ],
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