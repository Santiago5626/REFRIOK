import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart' as app_user;
import 'home_screen.dart';
import 'admin_panel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        app_user.User? user = await _authService.signIn(
          _emailController.text,
          _passwordController.text,
        );

        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        if (user != null) {
          if (user.isAdmin) {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminPanel()),
            );
          } else if (user.isBlocked) {
            if (!mounted) return;
            _showBlockedDialog();
          } else {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        
        String errorMessage = e.toString();
        // Remove any "Exception: " prefix from the error message
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring('Exception: '.length);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  void _showBlockedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cuenta Bloqueada'),
          content: const Text(
            'Tu cuenta está bloqueada por falta de pago. '
            'Por favor, realiza el pago correspondiente y contacta al administrador.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Entendido'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.handyman,
                    size: 100,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Refri OK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su correo';
                      }
                      if (!value.contains('@')) {
                        return 'Por favor ingrese un correo válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su contraseña';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Iniciar Sesión',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
