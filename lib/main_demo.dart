import 'package:flutter/material.dart';
import 'screens/login_screen_demo.dart';
import 'screens/home_screen_demo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tech Service App - Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapperDemo(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapperDemo extends StatefulWidget {
  const AuthWrapperDemo({super.key});

  @override
  State<AuthWrapperDemo> createState() => _AuthWrapperDemoState();
}

class _AuthWrapperDemoState extends State<AuthWrapperDemo> {
  bool isLoggedIn = false;

  String? userRole;

  void _login(String role) {
    setState(() {
      isLoggedIn = true;
      userRole = role;
    });
  }

  void _logout() {
    setState(() {
      isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoggedIn) {
      return HomeScreen(onLogout: _logout, userRole: userRole!);
    } else {
      return LoginScreenDemo(onLogin: _login);
    }
  }
}
