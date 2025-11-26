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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
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
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.getUserNotifications(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          List<Map<String, dynamic>> notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No tienes notificaciones',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 3,
      color: isRead ? Colors.grey[50] : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(type),
          child: Icon(
            _getNotificationIcon(type),
            color: Colors.white,
          ),
        ),
        title: Text(
          notification['title'] ?? '',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification['message'] ?? '',
              style: TextStyle(
                color: isRead ? Colors.grey[600] : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDateTime(createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
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
                child: ListTile(
                  leading: Icon(Icons.mark_email_read),
                  title: Text('Marcar como leída'),
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
        onTap: () async {
          if (!isRead) {
            await _notificationService.markAsRead(notification['id']);
          }
          
          // Si es una notificación de servicio, navegar a los detalles
          if (type == 'service_assignment' && notification['data'] != null) {
            final serviceId = notification['data']['serviceId'];
            if (serviceId != null) {
              // Obtener el servicio usando el ServiceManagementService
              final ServiceManagementService serviceService = ServiceManagementService();
              serviceService.getAllServices().listen((services) {
                try {
                  final service = services.firstWhere(
                    (s) => s.id == serviceId,
                  );
                  
                  if (mounted) {
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
                  }
                } catch (e) {
                  print('Servicio no encontrado: $e');
                }
              }).onError((error) {
                print('Error al obtener el servicio: $error');
              });
            }
          }
        },
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'service_assignment':
        return Colors.blue;
      case 'service_status_change':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'service_assignment':
        return Icons.assignment;
      case 'service_status_change':
        return Icons.update;
      default:
        return Icons.notifications;
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
}
