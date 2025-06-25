import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> initialize() async {
    try {
      // Solo inicializar en plataformas móviles
      if (!kIsWeb) {
        // Solicitar permisos
        NotificationSettings settings = await _firebaseMessaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          print('Usuario otorgó permisos de notificación');
        } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
          print('Usuario otorgó permisos provisionales');
        } else {
          print('Usuario denegó permisos de notificación');
        }

        // Configurar notificaciones locales solo en móviles
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        
        const InitializationSettings initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
        );

        await _localNotifications.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            // Manejar cuando el usuario toca la notificación
            print('Notificación tocada: ${response.payload}');
          },
        );

        // Configurar el canal de notificación para Android
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'service_assignments', // id
          'Asignaciones de Servicio', // title
          description: 'Notificaciones cuando se asigna un servicio a un técnico',
          importance: Importance.high,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      // Manejar mensajes cuando la app está en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Mensaje recibido en primer plano: ${message.notification?.title}');
        if (!kIsWeb) {
          _showLocalNotification(message);
        }
      });

      // Manejar cuando la app se abre desde una notificación
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App abierta desde notificación: ${message.notification?.title}');
        // Aquí puedes navegar a una pantalla específica
      });
    } catch (e) {
      print('Error initializing notifications: $e');
      // No lanzar el error para evitar que bloquee la app
    }
  }

  Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');
      return token;
    } catch (e) {
      print('Error obteniendo token FCM: $e');
      return null;
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'service_assignments',
      'Asignaciones de Servicio',
      channelDescription: 'Notificaciones cuando se asigna un servicio a un técnico',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Nuevo Servicio',
      message.notification?.body ?? 'Se te ha asignado un nuevo servicio',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  Future<void> showServiceAssignmentNotification({
    required String serviceTitle,
    required String clientName,
    required String location,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'service_assignments',
      'Asignaciones de Servicio',
      channelDescription: 'Notificaciones cuando se asigna un servicio a un técnico',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Nuevo Servicio Asignado',
      '$serviceTitle - Cliente: $clientName\nUbicación: $location',
      platformChannelSpecifics,
    );
  }

  // Notificar asignación de servicio
  Future<void> notifyServiceAssignment({
    required String technicianId,
    required String serviceId,
    required String serviceTitle,
    required String clientName,
    required String location,
  }) async {
    // Crear notificación en Firestore
    await _createNotification(
      userId: technicianId,
      title: 'Nuevo Servicio Asignado',
      message: '$serviceTitle - Cliente: $clientName\nUbicación: $location',
      type: 'service_assignment',
      data: {
        'serviceId': serviceId,
        'serviceTitle': serviceTitle,
        'clientName': clientName,
        'location': location,
      },
    );

    // Mostrar notificación local
    await showServiceAssignmentNotification(
      serviceTitle: serviceTitle,
      clientName: clientName,
      location: location,
    );

    // Enviar notificación FCM al técnico
    await subscribeToTopic('technician_$technicianId');
  }

  // Notificar cambio de estado del servicio
  Future<void> notifyServiceStatusChange({
    required String serviceId,
    required String serviceTitle,
    required String newStatus,
    required String technicianId,
    String? clientName,
  }) async {
    String message = 'El servicio "$serviceTitle" ha cambiado a estado: $newStatus';
    if (clientName != null) {
      message += '\nCliente: $clientName';
    }

    // Crear notificación en Firestore
    await _createNotification(
      userId: technicianId,
      title: 'Actualización de Servicio',
      message: message,
      type: 'service_status_change',
      data: {
        'serviceId': serviceId,
        'serviceTitle': serviceTitle,
        'newStatus': newStatus,
        'clientName': clientName,
      },
    );

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'service_status',
      'Estado de Servicios',
      channelDescription: 'Notificaciones de cambios en el estado de servicios',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      serviceId.hashCode,
      'Actualización de Servicio',
      message,
      platformChannelSpecifics,
    );
  }

  // Get unread notifications count
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
      throw e;
    }
  }

  // Get user notifications
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
                  'createdAt': (doc.data()['createdAt'] as Timestamp)
                      .toDate()
                      .toIso8601String(),
                })
            .toList());
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
      throw e;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
      throw e;
    }
  }

  // Create notification in Firestore
  Future<void> _createNotification({
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
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': data ?? {},
      });
    } catch (e) {
      print('Error creating notification: $e');
      throw e;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Suscrito al topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Desuscrito del topic: $topic');
  }

  // Obtener el ID del administrador
  Future<String?> _getAdminId() async {
    try {
      QuerySnapshot adminQuery = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .limit(1)
          .get();

      if (adminQuery.docs.isNotEmpty) {
        return adminQuery.docs.first.id;
      }
      return null;
    } catch (e) {
      print('Error al obtener ID del admin: $e');
      return null;
    }
  }

  // Convertir estado a texto legible
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'assigned':
        return 'Asignado';
      case 'onWay':
        return 'En camino';
      case 'inProgress':
        return 'En progreso';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      case 'paid':
        return 'Pagado';
      default:
        return status;
    }
  }

  // Notificar bloqueo de técnico
  Future<void> notifyTechnicianBlocked({
    required String technicianId,
    required String reason,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': technicianId,
        'title': 'Cuenta Bloqueada',
        'message': 'Tu cuenta ha sido bloqueada temporalmente. Razón: $reason',
        'type': 'technician_blocked',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Mostrar notificación local
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'account_status',
        'Estado de Cuenta',
        channelDescription: 'Notificaciones sobre el estado de la cuenta',
        importance: Importance.high,
        priority: Priority.high,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _localNotifications.show(
        'blocked_$technicianId'.hashCode,
        'Cuenta Bloqueada',
        'Tu cuenta ha sido bloqueada temporalmente. Razón: $reason',
        platformChannelSpecifics,
      );
    } catch (e) {
      print('Error al notificar bloqueo de técnico: $e');
    }
  }

  // Notificar desbloqueo de técnico
  Future<void> notifyTechnicianUnblocked({
    required String technicianId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': technicianId,
        'title': 'Cuenta Desbloqueada',
        'message': 'Tu cuenta ha sido desbloqueada. Ya puedes aceptar nuevos servicios.',
        'type': 'technician_unblocked',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Mostrar notificación local
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'account_status',
        'Estado de Cuenta',
        channelDescription: 'Notificaciones sobre el estado de la cuenta',
        importance: Importance.high,
        priority: Priority.high,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _localNotifications.show(
        'unblocked_$technicianId'.hashCode,
        'Cuenta Desbloqueada',
        'Tu cuenta ha sido desbloqueada. Ya puedes aceptar nuevos servicios.',
        platformChannelSpecifics,
      );
    } catch (e) {
      print('Error al notificar desbloqueo de técnico: $e');
    }
  }
}

// Función para manejar mensajes en segundo plano
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Mensaje recibido en segundo plano: ${message.notification?.title}');
}
