import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';

class CameraScreen extends StatefulWidget {
  final CameraController controller;

  const CameraScreen({
    super.key,
    required this.controller,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    // Garante que o controlador esteja inicializado antes de tentar usá-lo
    if (!widget.controller.value.isInitialized) {
      widget.controller.initialize().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _takePicture() async {
    if (_isCapturing || !widget.controller.value.isInitialized) return;

    setState(() => _isCapturing = true);

    try {
      // 1. Tira a foto
      final image = await widget.controller.takePicture();
      // 2. Salva a foto no dispositivo
      final savedPath = await CameraService.instance.savePicture(image);

      // 3. Retorna o caminho da foto salva para a tela anterior (o formulário)
      if (mounted) {
        Navigator.pop(context, savedPath);
      }
    } catch (e) {
      print('❌ Erro ao capturar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostra um loading enquanto a câmera inicializa
    if (!widget.controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Tela principal da câmera
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Visualização da câmera
          Center(child: CameraPreview(widget.controller)),

          // Botões de controle na parte inferior
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botão de fechar
                    IconButton(
                      onPressed: _isCapturing 
                        ? null 
                        : () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white, size: 32),
                    ),

                    // Botão de capturar
                    GestureDetector(
                      onTap: _isCapturing ? null : _takePicture,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: _isCapturing 
                            ? Colors.grey.withOpacity(0.5)
                            : Colors.transparent,
                        ),
                        child: _isCapturing
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Icon(Icons.camera, color: Colors.white, size: 40),
                      ),
                    ),

                    const SizedBox(width: 48), // Espaço vazio para centralizar o botão
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}