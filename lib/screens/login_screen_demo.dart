import 'package:flutter/material.dart';

class LoginScreenDemo extends StatefulWidget {
  final Function(String) onLogin;
  
  const LoginScreenDemo({super.key, required this.onLogin});

  @override
  State<LoginScreenDemo> createState() => _LoginScreenDemoState();
}

class _LoginScreenDemoState extends State<LoginScreenDemo> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión - Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.engineering,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              const Text(
                'Tech Service App',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su usuario';
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
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ingresar'),
              ),
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Credenciales de prueba:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('Admin: admin / admin123'),
                      Text('Técnico: tecnico1 / tecnico123'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text;
      final password = _passwordController.text;
      
      String? role;
      
      // Simulación de autenticación
      if (username == 'admin' && password == 'admin123') {
        role = 'admin';
      } else if (username == 'tecnico1' && password == 'tecnico123') {
        role = 'tecnico';
      }
      
      if (role != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Inicio de sesión exitoso como $role!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onLogin(role);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciales incorrectas'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
