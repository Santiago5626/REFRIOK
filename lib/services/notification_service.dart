import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crear una notificación
  Future<bool> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'data': data,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error al crear notificación: $e');
      return false;
    }
  }

  // Obtener notificaciones de un usuario
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  // Marcar notificación como leída
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error al marcar notificación como leída: $e');
      return false;
    }
  }

  // Marcar todas las notificaciones como leídas
  Future<bool> markAllAsRead(String userId) async {
    try {
      QuerySnapshot notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();
      for (QueryDocumentSnapshot doc in notifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error al marcar todas las notificaciones como leídas: $e');
      return false;
    }
  }

  // Obtener cantidad de notificaciones no leídas
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Eliminar notificación
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      return true;
    } catch (e) {
      print('Error al eliminar notificación: $e');
      return false;
    }
  }

  // Notificación específica para asignación de servicio
  Future<bool> notifyServiceAssignment({
    required String technicianId,
    required String serviceId,
    required String serviceTitle,
    required String clientName,
    required String location,
  }) async {
    return await createNotification(
      userId: technicianId,
      title: 'Nuevo Servicio Asignado',
      message: 'Se te ha asignado el servicio "$serviceTitle" para el cliente $clientName en $location',
      type: 'service_assignment',
      data: {
        'serviceId': serviceId,
        'serviceTitle': serviceTitle,
        'clientName': clientName,
        'location': location,
      },
    );
  }

  // Notificación para cambio de estado de servicio
  Future<bool> notifyServiceStatusChange({
    required String userId,
    required String serviceId,
    required String serviceTitle,
    required String newStatus,
    String? message,
  }) async {
    String statusText = _getStatusText(newStatus);
    
    return await createNotification(
      userId: userId,
      title: 'Estado de Servicio Actualizado',
      message: message ?? 'El servicio "$serviceTitle" cambió a estado: $statusText',
      type: 'service_status_change',
      data: {
        'serviceId': serviceId,
        'serviceTitle': serviceTitle,
        'newStatus': newStatus,
      },
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'assigned':
        return 'Asignado';
      case 'onWay':
        return 'En Camino';
      case 'inProgress':
        return 'En Progreso';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }
}
