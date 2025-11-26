import 'dart:async';
import 'package:flutter/foundation.dart';
import 'service_management_service.dart';

class SchedulerService {
  static SchedulerService? _instance;
  static SchedulerService get instance => _instance ??= SchedulerService._();

  SchedulerService._();

  Timer? _dailyCheckTimer;
  final ServiceManagementService _serviceManagementService =
      ServiceManagementService();

  // Inicializar el servicio de programación
  void initialize() {
    _scheduleDailyCheck();
    debugPrint('SchedulerService inicializado');
  }

  // Programar verificación diaria a las 10 PM
  void _scheduleDailyCheck() {
    // Cancelar timer anterior si existe
    _dailyCheckTimer?.cancel();

    // Calcular tiempo hasta las 10 PM de hoy
    final now = DateTime.now();
    final today10PM = DateTime(now.year, now.month, now.day, 22, 0, 0);

    DateTime nextCheck;
    if (now.isBefore(today10PM)) {
      // Si aún no son las 10 PM de hoy, programar para hoy
      nextCheck = today10PM;
    } else {
      // Si ya pasaron las 10 PM, programar para mañana
      nextCheck = today10PM.add(const Duration(days: 1));
    }

    final timeUntilCheck = nextCheck.difference(now);

    debugPrint('Próxima verificación de bloqueo programada para: $nextCheck');
    debugPrint(
        'Tiempo hasta la verificación: ${timeUntilCheck.inHours}h ${timeUntilCheck.inMinutes % 60}m');

    _dailyCheckTimer = Timer(timeUntilCheck, () {
      _performDailyCheck();
      // Reprogramar para el siguiente día
      _scheduleDailyCheck();
    });
  }

  // Ejecutar verificación diaria
  Future<void> _performDailyCheck() async {
    try {
      debugPrint('Ejecutando verificación diaria de bloqueo de técnicos...');
      // Solo ejecutar si hay un usuario admin autenticado
      // La verificación se hace en el método checkAndBlockTechnicians
      await _serviceManagementService.checkAndBlockTechnicians();
      debugPrint('Verificación diaria completada');
    } catch (e) {
      debugPrint('Error en verificación diaria: $e');
    }
  }

  // Ejecutar verificación manual (para testing)
  Future<void> runManualCheck() async {
    debugPrint('Ejecutando verificación manual...');
    await _performDailyCheck();
  }

  // Detener el servicio
  void dispose() {
    _dailyCheckTimer?.cancel();
    _dailyCheckTimer = null;
    debugPrint('SchedulerService detenido');
  }

  // Verificar si el servicio está activo
  bool get isActive => _dailyCheckTimer?.isActive ?? false;

  // Obtener tiempo hasta la próxima verificación
  Duration? get timeUntilNextCheck {
    if (_dailyCheckTimer == null || !_dailyCheckTimer!.isActive) {
      return null;
    }

    final now = DateTime.now();
    final today10PM = DateTime(now.year, now.month, now.day, 22, 0, 0);

    DateTime nextCheck;
    if (now.isBefore(today10PM)) {
      nextCheck = today10PM;
    } else {
      nextCheck = today10PM.add(const Duration(days: 1));
    }

    return nextCheck.difference(now);
  }
}
