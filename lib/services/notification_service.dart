import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static Future<void> initialize() async {
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

    // Configurar notificaciones locales
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

    // Manejar mensajes cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Mensaje recibido en primer plano: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Manejar cuando la app se abre desde una notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App abierta desde notificación: ${message.notification?.title}');
      // Aquí puedes navegar a una pantalla específica
    });
  }

  static Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');
      return token;
    } catch (e) {
      print('Error obteniendo token FCM: $e');
      return null;
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
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

  static Future<void> showServiceAssignmentNotification({
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
  static Future<void> notifyServiceAssignment({
    required String technicianId,
    required String serviceId,
    required String serviceTitle,
    required String clientName,
    required String location,
  }) async {
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
  static Future<void> notifyServiceStatusChange({
    required String serviceId,
    required String serviceTitle,
    required String newStatus,
    required String technicianId,
    String? clientName,
  }) async {
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

    String message = 'El servicio "$serviceTitle" ha cambiado a estado: $newStatus';
    if (clientName != null) {
      message += '\nCliente: $clientName';
    }

    await _localNotifications.show(
      serviceId.hashCode,
      'Actualización de Servicio',
      message,
      platformChannelSpecifics,
    );
  }

  // Obtener conteo de notificaciones no leídas
  static Future<int> getUnreadCount() async {
    // Implementar lógica para obtener conteo de notificaciones no leídas
    return 0;
  }

  // Marcar todas las notificaciones como leídas
  static Future<void> markAllAsRead() async {
    // Implementar lógica para marcar todas las notificaciones como leídas
  }

  // Obtener notificaciones del usuario
  static Stream<List<Map<String, dynamic>>> getUserNotifications() {
    // Implementar lógica para obtener notificaciones del usuario
    return Stream.value([]);
  }

  // Marcar notificación como leída
  static Future<void> markAsRead(String notificationId) async {
    // Implementar lógica para marcar notificación como leída
  }

  // Eliminar notificación
  static Future<void> deleteNotification(String notificationId) async {
    // Implementar lógica para eliminar notificación
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Suscrito al topic: $topic');
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Desuscrito del topic: $topic');
  }
}

// Función para manejar mensajes en segundo plano
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Mensaje recibido en segundo plano: ${message.notification?.title}');
}
