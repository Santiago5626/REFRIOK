import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final User initialUser;
  final VoidCallback? onSignOut;

  const ProfileScreen({
    super.key,
    required this.initialUser,
    this.onSignOut,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _getUserStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final user = snapshot.data ?? widget.initialUser;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(user),
              const SizedBox(height: 24),
              _buildStatsCard(user),
              const SizedBox(height: 16),
              _buildPaymentInfo(user),
              const SizedBox(height: 16),
              _buildHelpCard(context),
              if (widget.onSignOut != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar Sesión'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Stream<User?> _getUserStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.initialUser.id)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return User.fromMap({
          'id': doc.id,
          ...doc.data()!,
        });
      }
      return null;
    });
  }

  Widget _buildProfileHeader(User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.username,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Servicios\nCompletados',
                  user.completedServices.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  'Ganancias\nTotales',
                  '\$${user.totalEarnings.toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.amber,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 40,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo(User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de Pagos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  user.isBlocked ? Icons.block : Icons.check_circle,
                  color: user.isBlocked ? Colors.red : Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  user.isBlocked
                      ? 'Cuenta Bloqueada'
                      : 'Cuenta Activa',
                  style: TextStyle(
                    fontSize: 16,
                    color: user.isBlocked ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Último pago: ${user.lastPaymentDate != null ? _formatDate(user.lastPaymentDate!) : 'No hay pagos registrados'}',
              style: const TextStyle(fontSize: 16),
            ),
            if (user.isBlocked) ...[
              const SizedBox(height: 16),
              const Text(
                'Tu cuenta está bloqueada por falta de pago. Por favor, realiza el pago correspondiente y contacta al administrador.',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ayuda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.help, color: Colors.blue),
              title: const Text('¿Cómo funciona el sistema de pagos?'),
              subtitle: const Text(
                'Debes pagar el 30% de cada servicio. El pago debe realizarse el mismo día.',
              ),
              onTap: () {
                _showPaymentInfoDialog(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.support_agent, color: Colors.green),
              title: const Text('Contactar soporte'),
              subtitle: const Text('¿Tienes problemas? Contáctanos'),
              onTap: () {
                _showSupportDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sistema de Pagos'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '1. Comisiones:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• 70% para el técnico'),
                Text('• 30% para la administración'),
                SizedBox(height: 12),
                Text(
                  '2. Plazos de pago:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Debes pagar el mismo día del servicio'),
                Text('• El sistema bloquea automáticamente a las 10 PM'),
                SizedBox(height: 12),
                Text(
                  '3. Servicios:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Revisión: \$30.000 fijos'),
                Text('• Servicio completo: Precio variable'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contactar Soporte'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para cualquier problema o consulta, contáctanos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• Horario de atención: 8 AM - 8 PM'),
              Text('• WhatsApp: +57 324 440 6860'),
              Text('• Nombre: Jose David Lobo'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
