import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/service_management_service.dart';
import '../screens/service_detail_screen.dart';
import '../utils/dialog_utils.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final ServiceManagementService _serviceService = ServiceManagementService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() async {
    final user = await _authService.getCurrentUserData();
    if (user != null) {
      setState(() {
        _currentUserId = user.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0052CC))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            color: Color(0xFF172B4D),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF172B4D)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read_outlined, color: Color(0xFF0052CC)),
            tooltip: 'Marcar todas como leídas',
            onPressed: () async {
              try {
                await _notificationService.markAllAsRead(_currentUserId!);
                if (!mounted) return;
                await showAnimatedDialog(
                  context,
                  DialogType.success,
                  'Todas las notificaciones marcadas como leídas',
                );
              } catch (e) {
                if (!mounted) return;
                await showAnimatedDialog(
                  context,
                  DialogType.error,
                  'Error al marcar notificaciones: $e',
                );
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF172B4D)),
            tooltip: 'Opciones',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) async {
              if (value == 'delete_all') {
                _showDeleteAllConfirmation();
              } else if (value == 'mute') {
                _showMuteOptions();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 20, color: Color(0xFFFFAB00)),
                    SizedBox(width: 12),
                    Text('Silenciar notificaciones'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, size: 20, color: Color(0xFFFF5630)),
                    SizedBox(width: 12),
                    Text('Eliminar todas', style: TextStyle(color: Color(0xFFFF5630))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.getUserNotifications(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0052CC)));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          List<Map<String, dynamic>> notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0052CC).withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 64,
                      color: Color(0xFF0052CC),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No tienes notificaciones',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172B4D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Te avisaremos cuando haya novedades',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF5E6C84),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final bool isRead = notification['isRead'] ?? false;
    final String type = notification['type'] ?? '';
    
    DateTime createdAt;
    final dynamic rawCreatedAt = notification['createdAt'];
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.parse(rawCreatedAt);
    } else {
      createdAt = DateTime.now();
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isRead ? const Color(0xFFF4F5F7) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172B4D).withValues(alpha: isRead ? 0.02 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          if (!isRead)
            BoxShadow(
              color: const Color(0xFF172B4D).withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
        border: isRead ? Border.all(color: Colors.transparent) : Border.all(color: const Color(0xFF0052CC).withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            if (!isRead) {
              await _notificationService.markAsRead(notification['id']);
            }
            
            // Si es una notificación de servicio, navegar a los detalles
            if (type == 'service_assignment' && notification['data'] != null) {
              final serviceId = notification['data']['serviceId'];
              if (serviceId != null) {
                try {
                  final service = await _serviceService.getServiceById(serviceId);
                  
                  if (mounted && service != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceDetailScreen(
                          service: service,
                          // El servicio no está disponible porque ya está asignado
                          isAvailable: false,
                        ),
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('El servicio ya no está disponible')),
                    );
                  }
                } catch (e) {
                  print('Error al obtener el servicio: $e');
                }
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(type),
                    color: _getNotificationColor(type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'] ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                color: const Color(0xFF172B4D),
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0052CC),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification['message'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: isRead ? const Color(0xFF5E6C84) : const Color(0xFF172B4D),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDateTime(createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5E6C84),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          PopupMenuButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.more_horiz, color: Color(0xFF5E6C84)),
                            onSelected: (value) async {
                              if (value == 'mark_read') {
                                await _notificationService.markAsRead(notification['id']);
                              } else if (value == 'delete') {
                                await _notificationService.deleteNotification(notification['id']);
                              }
                            },
                            itemBuilder: (context) => [
                              if (!isRead)
                                const PopupMenuItem(
                                  value: 'mark_read',
                                  child: Row(
                                    children: [
                                      Icon(Icons.mark_email_read_outlined, size: 20, color: Color(0xFF0052CC)),
                                      SizedBox(width: 12),
                                      Text('Marcar como leída'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 20, color: Color(0xFFFF5630)),
                                    SizedBox(width: 12),
                                    Text('Eliminar', style: TextStyle(color: Color(0xFFFF5630))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'service_assignment':
        return const Color(0xFF0052CC); // Blue
      case 'service_status_change':
        return const Color(0xFFFFAB00); // Yellow/Orange
      case 'payment':
        return const Color(0xFF36B37E); // Green
      case 'alert':
        return const Color(0xFFFF5630); // Red
      default:
        return const Color(0xFF6554C0); // Purple
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'service_assignment':
        return Icons.assignment_ind_outlined;
      case 'service_status_change':
        return Icons.update;
      case 'payment':
        return Icons.attach_money;
      case 'alert':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} día${difference.inDays > 1 ? 's' : ''} atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora${difference.inHours > 1 ? 's' : ''} atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''} atrás';
    } else {
      return 'Ahora';
    }
  }

  void _showDeleteAllConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5630).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFFF5630)),
            ),
            const SizedBox(width: 12),
            const Text('Eliminar todas'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar todas las notificaciones? Esta acción no se puede deshacer.',
          style: TextStyle(color: Color(0xFF172B4D)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF5E6C84))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _notificationService.deleteAllNotifications(_currentUserId!);
                if (!mounted) return;
                await showAnimatedDialog(
                  context,
                  DialogType.success,
                  'Todas las notificaciones han sido eliminadas',
                );
              } catch (e) {
                if (!mounted) return;
                await showAnimatedDialog(
                  context,
                  DialogType.error,
                  'Error al eliminar notificaciones: $e',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5630),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Eliminar todas'),
          ),
        ],
      ),
    );
  }

  void _showMuteOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFAB00).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications_off_outlined, color: Color(0xFFFFAB00)),
            ),
            const SizedBox(width: 12),
            const Text('Silenciar notificaciones'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selecciona por cuánto tiempo deseas silenciar las notificaciones:',
              style: TextStyle(color: Color(0xFF172B4D)),
            ),
            const SizedBox(height: 20),
            _buildMuteOption('15 minutos', () {
              Navigator.pop(context);
              _muteNotifications(15);
            }),
            const SizedBox(height: 12),
            _buildMuteOption('1 hora', () {
              Navigator.pop(context);
              _muteNotifications(60);
            }),
            const SizedBox(height: 12),
            _buildMuteOption('8 horas', () {
              Navigator.pop(context);
              _muteNotifications(480);
            }),
            const SizedBox(height: 12),
            _buildMuteOption('Hasta que las active', () {
              Navigator.pop(context);
              _muteNotifications(-1);
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF5E6C84))),
          ),
        ],
      ),
    );
  }

  Widget _buildMuteOption(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDFE1E6)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF172B4D),
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  void _muteNotifications(int minutes) {
    String message;
    if (minutes == -1) {
      message = 'Notificaciones silenciadas hasta que las actives manualmente';
    } else if (minutes < 60) {
      message = 'Notificaciones silenciadas por $minutes minutos';
    } else {
      final hours = minutes ~/ 60;
      message = 'Notificaciones silenciadas por $hours hora${hours > 1 ? 's' : ''}';
    }
    
    showAnimatedDialog(
      context,
      DialogType.success,
      message,
    );
    
    // Aquí podrías implementar la lógica real de silenciar notificaciones
    // Por ejemplo, guardar en SharedPreferences o en Firestore
  }
}
