import 'package:flutter/material.dart';

class AnimatedConfirmationMessage extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color color;
  final Duration duration;
  final VoidCallback? onDismiss;

  const AnimatedConfirmationMessage({
    super.key,
    required this.message,
    required this.icon,
    this.color = Colors.green,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
  });

  @override
  State<AnimatedConfirmationMessage> createState() => _AnimatedConfirmationMessageState();

  static void show(
    BuildContext context, {
    required String message,
    required IconData icon,
    Color color = Colors.green,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => AnimatedConfirmationMessage(
        message: message,
        icon: icon,
        color: color,
        duration: duration,
        onDismiss: () {
          overlayEntry.remove();
          onDismiss?.call();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _AnimatedConfirmationMessageState extends State<AnimatedConfirmationMessage>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controladores de animación
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Animaciones
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Iniciar animaciones
    _startAnimations();
    
    // Auto-dismiss después del duration especificado
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismissWithAnimation();
      }
    });
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _slideController.forward();
      _fadeController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        _scaleController.forward();
      }
    }
  }

  void _dismissWithAnimation() async {
    if (mounted) {
      await _scaleController.reverse();
      await _fadeController.reverse();
      await _slideController.reverse();
      widget.onDismiss?.call();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _dismissWithAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Widget para mostrar mensajes de éxito
class SuccessMessage {
  static void show(BuildContext context, String message) {
    AnimatedConfirmationMessage.show(
      context,
      message: message,
      icon: Icons.check_circle,
      color: Colors.green,
    );
  }
}

// Widget para mostrar mensajes de error
class ErrorMessage {
  static void show(BuildContext context, String message) {
    AnimatedConfirmationMessage.show(
      context,
      message: message,
      icon: Icons.error,
      color: Colors.red,
      duration: const Duration(seconds: 4),
    );
  }
}

// Widget para mostrar mensajes de información
class InfoMessage {
  static void show(BuildContext context, String message) {
    AnimatedConfirmationMessage.show(
      context,
      message: message,
      icon: Icons.info,
      color: Colors.blue,
    );
  }
}

// Widget para mostrar mensajes de advertencia
class WarningMessage {
  static void show(BuildContext context, String message) {
    AnimatedConfirmationMessage.show(
      context,
      message: message,
      icon: Icons.warning,
      color: Colors.orange,
    );
  }
}
