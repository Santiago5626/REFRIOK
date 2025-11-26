import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/scheduler_service.dart';
import 'models/user.dart' as app_user;
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/service_management_service.dart';

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

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Stream<firebase_auth.User?>? _authStream;
  Object? _error;

  @override
  void initState() {
    super.initState();
    // Move the potentially failing call to initState and wrap in a try-catch.
    try {
      _authStream = firebase_auth.FirebaseAuth.instance.authStateChanges();
    } catch (e) {
      // If it fails, store the error to show it in the build method.
      _error = e;
    }
  }

  @override
  Widget build(BuildContext context) {
    // If an error occurred during initialization, display it.
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Ocurrió un error al inicializar la autenticación de Firebase. '
              'Esto puede deberse a un problema de configuración o de conexión con los servicios de Google.\n\n'
              'Error: $_error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Show a loading indicator while the stream is being initialized.
    if (_authStream == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If initialization was successful, use the StreamBuilder.
    return StreamBuilder<firebase_auth.User?>(
      stream: _authStream!,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Error de autenticación. Verifique su conexión.'),
            ),
          );
        }

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

              if (userSnapshot.hasError) {
                return const Scaffold(
                  body: Center(
                    child: Text('Error al cargar los datos del usuario.'),
                  ),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data != null) {
                return const HomeScreen();
              } else {
                // This can happen if the user exists in Auth but not in Firestore.
                return const LoginScreen();
              }
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
