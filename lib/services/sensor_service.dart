import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

class SensorService {
  static final SensorService instance = SensorService._init();
  SensorService._init();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Function()? _onShake;

  // Limite de força para considerar um "shake"
  static const double _shakeThreshold = 15.0; 
  // Tempo de espera (cooldown) para evitar detecções múltiplas
  static const Duration _shakeCooldown = Duration(milliseconds: 500);

  DateTime? _lastShakeTime;
  bool _isActive = false;

  bool get isActive => _isActive;

  void startShakeDetection(Function() onShake) {
    if (_isActive) {
      print('⚠️ Detecção de shake já ativa');
      return;
    }

    _onShake = onShake;
    _isActive = true;

    // Começa a ouvir os eventos do acelerômetro
    _accelerometerSubscription = accelerometerEvents.listen(
      (AccelerometerEvent event) {
        _detectShake(event);
      },
      onError: (error) {
        print('❌ Erro no acelerômetro: $error');
      },
    );

    print('📱 Detecção de shake iniciada');
  }

  void _detectShake(AccelerometerEvent event) {
    final now = DateTime.now();

    // Se um shake acabou de acontecer, ignora este evento
    if (_lastShakeTime != null && 
        now.difference(_lastShakeTime!) < _shakeCooldown) {
      return;
    }

    // Calcula a magnitude da força do movimento
    final double magnitude = math.sqrt(
      event.x * event.x + 
      event.y * event.y + 
      event.z * event.z
    );

    // Se a força for maior que o nosso limite
    if (magnitude > _shakeThreshold) {
      print('🔳 Shake! Magnitude: ${magnitude.toStringAsFixed(2)}');
      _lastShakeTime = now;
      _vibrateDevice();
      _onShake?.call(); // Chama a função que foi passada (ex: mostrar diálogo)
    }
  }

  Future<void> _vibrateDevice() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 100);
      }
    } catch (e) {
      print('⚠️ Vibração não suportada: $e');
    }
  }

  void stop() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _onShake = null;
    _isActive = false;
    print('⏹️ Detecção de shake parada');
  }
}