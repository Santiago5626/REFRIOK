import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

enum NotificationType { success, error, loading, warning }

class ModernNotification extends StatefulWidget {
  final NotificationType type;
  final String message;
  final String? subtitle;
  final VoidCallback? onDismiss;
  final Duration? autoDismissDuration;

  const ModernNotification({
    super.key,
    required this.type,
    required this.message,
    this.subtitle,
    this.onDismiss,
    this.autoDismissDuration,
  });

  @override
  State<ModernNotification> createState() => _ModernNotificationState();

  /// Muestra una notificación moderna con overlay
  static void show(
    BuildContext context, {
    required NotificationType type,
    required String message,
    String? subtitle,
    Duration? duration,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => ModernNotificationOverlay(
        type: type,
        message: message,
        subtitle: subtitle,
        onDismiss: () {
          overlayEntry.remove();
        },
        autoDismissDuration: duration ?? const Duration(seconds: 3),
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _ModernNotificationState extends State<ModernNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.25, 0.1, 0.25, 1),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.25, 0.1, 0.25, 1),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor() {
    switch (widget.type) {
      case NotificationType.success:
        return const Color(0xFF22c55e); // Verde moderno
      case NotificationType.error:
        return const Color(0xFFef4444); // Rojo moderno
      case NotificationType.warning:
        return const Color(0xFFfacc15); // Amarillo cálido
      case NotificationType.loading:
        return const Color(0xFF1E88E5); // Azul
    }
  }

  String _getAnimationPath() {
    switch (widget.type) {
      case NotificationType.success:
        return 'assets/animations/success_modern.json';
      case NotificationType.error:
        return 'assets/animations/error_modern.json';
      case NotificationType.loading:
        return 'assets/animations/loading_modern.json';
      case NotificationType.warning:
        return 'assets/animations/success_modern.json'; // Usar success por ahora
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _getColor().withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: _getColor().withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animación Lottie
            SizedBox(
              width: 120,
              height: 120,
              child: Lottie.asset(
                _getAnimationPath(),
                fit: BoxFit.contain,
                repeat: widget.type == NotificationType.loading,
              ),
            ),
            const SizedBox(height: 16),
            // Mensaje principal
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
                height: 1.4,
              ),
            ),
            // Subtítulo opcional
            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget de overlay para mostrar la notificación con backdrop blur
class ModernNotificationOverlay extends StatefulWidget {
  final NotificationType type;
  final String message;
  final String? subtitle;
  final VoidCallback onDismiss;
  final Duration autoDismissDuration;

  const ModernNotificationOverlay({
    super.key,
    required this.type,
    required this.message,
    this.subtitle,
    required this.onDismiss,
    required this.autoDismissDuration,
  });

  @override
  State<ModernNotificationOverlay> createState() =>
      _ModernNotificationOverlayState();
}

class _ModernNotificationOverlayState extends State<ModernNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _overlayController;
  late Animation<double> _overlayOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _overlayOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _overlayController,
        curve: Curves.easeOut,
      ),
    );

    _overlayController.forward();

    // Auto-dismiss si no es loading
    if (widget.type != NotificationType.loading) {
      Future.delayed(widget.autoDismissDuration, () {
        _dismiss();
      });
    }
  }

  @override
  void dispose() {
    _overlayController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _overlayController.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: widget.type != NotificationType.loading ? _dismiss : null,
        child: AnimatedBuilder(
          animation: _overlayController,
          builder: (context, child) {
            return Opacity(
              opacity: _overlayOpacityAnimation.value,
              child: child,
            );
          },
          child: Stack(
            children: [
              // Backdrop blur overlay
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.black.withOpacity(0.25),
                  ),
                ),
              ),
              // Notificación centrada
              Center(
                child: ModernNotification(
                  type: widget.type,
                  message: widget.message,
                  subtitle: widget.subtitle,
                  onDismiss: _dismiss,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
