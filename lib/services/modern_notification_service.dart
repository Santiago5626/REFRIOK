import 'package:flutter/material.dart';
import '../widgets/modern_notification.dart';

/// Servicio centralizado para mostrar notificaciones UI modernas
class ModernNotificationService {
  /// Muestra una notificación de éxito
  static void showSuccess(
    BuildContext context,
    String message, {
    String? subtitle,
    Duration? duration,
  }) {
    ModernNotification.show(
      context,
      type: NotificationType.success,
      message: message,
      subtitle: subtitle,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Muestra una notificación de error
  static void showError(
    BuildContext context,
    String message, {
    String? subtitle,
    Duration? duration,
  }) {
    ModernNotification.show(
      context,
      type: NotificationType.error,
      message: message,
      subtitle: subtitle,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  /// Muestra una notificación de advertencia
  static void showWarning(
    BuildContext context,
    String message, {
    String? subtitle,
    Duration? duration,
  }) {
    ModernNotification.show(
      context,
      type: NotificationType.warning,
      message: message,
      subtitle: subtitle,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Muestra una notificación de carga (no se auto-cierra)
  static void showLoading(
    BuildContext context,
    String message, {
    String? subtitle,
  }) {
    ModernNotification.show(
      context,
      type: NotificationType.loading,
      message: message,
      subtitle: subtitle,
      duration: const Duration(days: 1), // No auto-cerrar
    );
  }
}
