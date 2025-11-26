import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  Future<void> saveTokenToUser(String userId) async {
    try {
      String? token = await getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('Token FCM guardado para el usuario $userId');
      }
    } catch (e) {
      print('Error guardando token FCM: $e');
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
      message: 'Se te ha asignado el servicio: $serviceTitle',
      type: 'service_assignment',
      data: {
        'serviceId': serviceId,
        'serviceTitle': serviceTitle,
        'clientName': clientName,
        'location': location,
      },
    );

    // Enviar notificación FCM al técnico
    // await subscribeToTopic('technician_$technicianId'); // REMOVIDO: El técnico se suscribe al iniciar sesión
    
    // Enviar Push Notification real usando el backend
    await sendPushNotification(
      userId: technicianId,
      title: 'Nuevo Servicio Asignado',
      body: 'Se te ha asignado el servicio: $serviceTitle',
      data: {
        'serviceId': serviceId,
        'type': 'service_assignment',
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
    );
  }

  // Notificar cambio de estado del servicio
  Future<void> notifyServiceStatusChange({
    required String serviceId,
    required String serviceTitle,
    required String newStatus,
    required String technicianId,
    String? clientName,
  }) async {
    String statusInSpanish = _getStatusText(newStatus);
    String message = 'El servicio "$serviceTitle" ha cambiado a: $statusInSpanish';
    if (clientName != null) {
      message += '\nCliente: $clientName';
    }

    // Notificar al administrador
    String? adminId = await _getAdminId();
    if (adminId != null) {
      await _createNotification(
        userId: adminId,
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
      
      // Enviar Push Notification real al admin
      await sendPushNotification(
        userId: adminId, // Ahora usa userId en lugar de technicianId
        title: 'Actualización de Servicio',
        body: message,
        data: {
          'serviceId': serviceId,
          'type': 'service_status_change',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      );
    }
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
    if (!kIsWeb) {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Suscrito al topic: $topic');
    } else {
      print(
          'Subscripción a topics no soportada en web, omitiendo para el topic: $topic');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (!kIsWeb) {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Desuscrito del topic: $topic');
    } else {
      print(
          'Desuscripción de topics no soportada en web, omitiendo para el topic: $topic');
    }
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
      await _createNotification(
        userId: technicianId,
        title: 'Cuenta Bloqueada',
        message: 'Tu cuenta ha sido bloqueada. Razón: $reason',
        type: 'technician_blocked',
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
      await _createNotification(
        userId: technicianId,
        title: 'Cuenta Desbloqueada',
        message: 'Tu cuenta ha sido desbloqueada y ya puedes operar con normalidad.',
        type: 'technician_unblocked',
      );
    } catch (e) {
      print('Error al notificar desbloqueo de técnico: $e');
    }
  }
  // Enviar notificación Push usando el backend
  Future<void> sendPushNotification({
    required String userId, // Cambiado de technicianId a userId para mayor claridad
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // URL del backend en Render
      const String backendUrl = 'https://refriok.onrender.com';

      if (backendUrl == 'YOUR_RENDER_BACKEND_URL') {
        print('⚠️ URL del backend no configurada. No se enviará la notificación push.');
        return;
      }

      final response = await http.post(
        Uri.parse('$backendUrl/sendPush'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId, // Cambiado de technicianId a userId
          'title': title,
          'body': body,
          'data': data,
          // 'apiKey': 'TU_API_KEY_SI_CONFIGURASTE_UNA',
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Notificación push enviada con éxito a $userId');
      } else {
        print('❌ Error enviando push: ${response.body}');
      }
    } catch (e) {
      print('❌ Error conectando con el backend de notificaciones: $e');
    }
  }

  // Get unread notifications count for a user
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      QuerySnapshot unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
      throw e;
    }
  }

  // Get user notifications stream
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return {
                'id': doc.id,
                ...doc.data(),
              };
            }).toList());
  }
}

// Función para manejar mensajes en segundo plano
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Mensaje recibido en segundo plano: ${message.notification?.title}');
}
