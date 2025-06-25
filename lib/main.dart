import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/scheduler_service.dart';
import 'models/user.dart' as app_user;
import 'services/auth_service.dart';
import 'services/notification_service.dart';

// Manejador de mensajes en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await firebaseMessagingBackgroundHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configurar manejador de mensajes en segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Inicializar servicios de forma no bloqueante
    _initializeServicesAsync();
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  runApp(const MyApp());
}

void _initializeServicesAsync() async {
  try {
    // Inicializar servicios en segundo plano
    final notificationService = NotificationService();
    await notificationService.initialize();

    // Inicializar el servicio de programación
    SchedulerService.instance.initialize();
  } catch (e) {
    print('Error initializing services: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REFRIOK',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E88E5), // Azul más profundo
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1E88E5), // Azul más profundo
            foregroundColor: Colors.white,
          ),
        ),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF1E88E5), // Azul más profundo
          secondary: Color(0xFF64B5F6), // Azul más claro
          tertiary: Color(0xFF42A5F5), // Azul intermedio
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return FutureBuilder<app_user.User?>(
            future: AuthService().getCurrentUserData(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              return const HomeScreen();
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
