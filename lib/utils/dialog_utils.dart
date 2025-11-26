import 'package:flutter/material.dart';
import '../services/modern_notification_service.dart';

enum DialogType { success, error, warning, loading }

/// Muestra un diálogo animado moderno
/// 
/// Usa el nuevo sistema de notificaciones con efectos glassmorphism,
/// animaciones Lottie modernas y colores actualizados.
Future<void> showAnimatedDialog(
  BuildContext context,
  DialogType type,
  String message, {
  String? subtitle,
  Duration? duration,
}) {
  switch (type) {
    case DialogType.success:
      ModernNotificationService.showSuccess(
        context,
        message,
        subtitle: subtitle,
        duration: duration,
      );
      break;
    case DialogType.error:
      ModernNotificationService.showError(
        context,
        message,
        subtitle: subtitle,
        duration: duration,
      );
      break;
    case DialogType.warning:
      ModernNotificationService.showWarning(
        context,
        message,
        subtitle: subtitle,
        duration: duration,
      );
      break;
    case DialogType.loading:
      ModernNotificationService.showLoading(
        context,
        message,
        subtitle: subtitle,
      );
      break;
  }
  
  // Retornar un Future completado para mantener compatibilidad
  return Future.value();
}
